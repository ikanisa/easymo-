import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DeeplinkController } from './deeplink.controller';
import { DeeplinkService } from './deeplink.service';
import * as crypto from '../../common/crypto';
import { env } from '../../common/env';

jest.mock('@easymo/commons', () => ({
  getApiControllerBasePath: (controller: string) => controller,
  getApiEndpointSegment: (controller: string, endpoint: string) => endpoint,
}));

describe('DeeplinkController', () => {
  let app: INestApplication;
  let service: DeeplinkService;
  const originalEnv = { ...env };

  beforeAll(() => {
    env.deeplinkSecret = 'test-deeplink-secret';
  });

  afterAll(() => {
    Object.assign(env, originalEnv);
  });

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [DeeplinkController],
      providers: [DeeplinkService],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();

    service = moduleRef.get<DeeplinkService>(DeeplinkService);
  });

  afterEach(async () => {
    await app.close();
  });

  describe('POST /issue', () => {
    it('should issue a token with valid input', async () => {
      const response = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'insurance_attach',
          payload: { policyNumber: '12345' },
        })
        .expect(201);

      expect(response.body).toHaveProperty('token');
      expect(typeof response.body.token).toBe('string');
      expect(response.body.token.length).toBeGreaterThan(0);
    });

    it('should issue a token with custom TTL', async () => {
      const response = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'basket_open',
          ttl: 3600, // 1 hour
        })
        .expect(201);

      expect(response.body).toHaveProperty('token');
    });

    it('should issue a token with MSISDN binding', async () => {
      const response = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'generate_qr',
          msisdn: '+1234567890',
        })
        .expect(201);

      expect(response.body).toHaveProperty('token');
    });

    it('should reject invalid flow type', async () => {
      await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'invalid_flow',
        })
        .expect(400);
    });

    it('should reject negative TTL', async () => {
      await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'insurance_attach',
          ttl: -100,
        })
        .expect(400);
    });
  });

  describe('POST /resolve', () => {
    it('should resolve a valid token', async () => {
      // First, issue a token
      const issueResponse = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'insurance_attach',
          payload: { policyNumber: '12345' },
        });

      const token = issueResponse.body.token;

      // Then resolve it
      const resolveResponse = await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({ token })
        .expect(201);

      expect(resolveResponse.body).toEqual({
        flow: 'insurance_attach',
        payload: { policyNumber: '12345' },
      });
    });

    it('should return 410 for expired token', async () => {
      // Create a token that expires immediately
      const expiredToken = await crypto.signJwt(
        { flow: 'basket_open', payload: {} },
        env.deeplinkSecret,
        1 // 1 second TTL
      );

      // Wait for token to expire
      await new Promise(resolve => setTimeout(resolve, 2000));

      await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({ token: expiredToken })
        .expect(410);
    });

    it('should return 403 when MSISDN is omitted for bound token', async () => {
      const issueResponse = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'insurance_attach',
          msisdn: '+1234567890',
        });

      const token = issueResponse.body.token;

      await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({
          token,
        })
        .expect(403);
    });

    it('should return 403 for MSISDN mismatch', async () => {
      // Issue a token with MSISDN binding
      const issueResponse = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'insurance_attach',
          msisdn: '+1234567890',
        });

      const token = issueResponse.body.token;

      // Try to resolve with different MSISDN
      await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({
          token,
          msisdn: '+9876543210',
        })
        .expect(403);
    });

    it('should resolve token with matching MSISDN', async () => {
      // Issue a token with MSISDN binding
      const issueResponse = await request(app.getHttpServer())
        .post('/deeplink/issue')
        .send({
          flow: 'generate_qr',
          msisdn: '+1234567890',
          payload: { qrData: 'test' },
        });

      const token = issueResponse.body.token;

      // Resolve with matching MSISDN
      const resolveResponse = await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({
          token,
          msisdn: '+1234567890',
        })
        .expect(201);

      expect(resolveResponse.body).toEqual({
        flow: 'generate_qr',
        payload: { qrData: 'test' },
      });
    });

    it('should return 401 for invalid token', async () => {
      await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({ token: 'invalid.token.here' })
        .expect(401);
    });

    it('should reject missing token', async () => {
      await request(app.getHttpServer())
        .post('/deeplink/resolve')
        .send({})
        .expect(400);
    });
  });

  describe('Token roundtrip', () => {
    it('should support all flow types', async () => {
      const flows = ['insurance_attach', 'basket_open', 'generate_qr'] as const;

      for (const flow of flows) {
        const issueResponse = await request(app.getHttpServer())
          .post('/deeplink/issue')
          .send({
            flow,
            payload: { testData: flow },
          });

        const token = issueResponse.body.token;

        const resolveResponse = await request(app.getHttpServer())
          .post('/deeplink/resolve')
          .send({ token })
          .expect(201);

        expect(resolveResponse.body.flow).toBe(flow);
        expect(resolveResponse.body.payload).toEqual({ testData: flow });
      }
    });
  });
});
