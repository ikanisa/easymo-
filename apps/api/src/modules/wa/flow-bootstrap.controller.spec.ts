import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { FlowBootstrapController } from './flow-bootstrap.controller';
import { DeeplinkService } from '../deeplink/deeplink.service';
import { env } from '../../common/env';

jest.mock('@easymo/commons', () => ({
  getApiControllerBasePath: (controller: string) => controller,
  getApiEndpointSegment: (controller: string, endpoint: string) => endpoint,
}));

describe('FlowBootstrapController', () => {
  let app: INestApplication;
  let deeplinkService: DeeplinkService;
  const originalEnv = { ...env };

  beforeAll(() => {
    env.deeplinkSecret = 'test-deeplink-secret';
  });

  afterAll(() => {
    Object.assign(env, originalEnv);
  });

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [FlowBootstrapController],
      providers: [DeeplinkService],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ transform: true }));
    await app.init();

    deeplinkService = moduleRef.get<DeeplinkService>(DeeplinkService);
  });

  afterEach(async () => {
    await app.close();
  });

  describe('POST /bootstrap', () => {
    it('should bootstrap insurance_attach flow', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'insurance_attach',
        payload: { policyType: 'health' },
        ttl: 3600,
      });

      const response = await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token })
        .expect(201);

      expect(response.body.flow).toBe('insurance_attach');
      expect(response.body.payload).toEqual({ policyType: 'health' });
      expect(response.body.flowState).toHaveProperty('type', 'text');
      expect(response.body.flowState).toHaveProperty('content');
      expect(response.body.flowState.content).toContain('insurance');
    });

    it('should bootstrap basket_open flow', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'basket_open',
        payload: { basketId: 'basket-123' },
        ttl: 3600,
      });

      const response = await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token })
        .expect(201);

      expect(response.body.flow).toBe('basket_open');
      expect(response.body.payload).toEqual({ basketId: 'basket-123' });
      expect(response.body.flowState).toHaveProperty('type', 'text');
      expect(response.body.flowState.content).toContain('basket-123');
    });

    it('should bootstrap basket_open flow without basketId', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'basket_open',
        ttl: 3600,
      });

      const response = await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token })
        .expect(201);

      expect(response.body.flow).toBe('basket_open');
      expect(response.body.flowState).toHaveProperty('type', 'text');
      expect(response.body.flowState.content).toContain('basket');
    });

    it('should bootstrap generate_qr flow', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'generate_qr',
        payload: { data: 'test-data' },
        ttl: 3600,
      });

      const response = await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token })
        .expect(201);

      expect(response.body.flow).toBe('generate_qr');
      expect(response.body.payload).toEqual({ data: 'test-data' });
      expect(response.body.flowState).toHaveProperty('type', 'text');
      expect(response.body.flowState.content).toContain('QR');
    });

    it('should return 410 for expired token', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'insurance_attach',
        ttl: 1, // 1 second
      });

      // Wait for token to expire
      await new Promise(resolve => setTimeout(resolve, 2000));

      await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token })
        .expect(410);
    });

    it('should return 403 when MSISDN is omitted for bound token', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'basket_open',
        msisdn: '+1234567890',
        ttl: 3600,
      });

      await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({
          token,
        })
        .expect(403);
    });

    it('should return 403 for MSISDN mismatch', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'basket_open',
        msisdn: '+1234567890',
        ttl: 3600,
      });

      await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({
          token,
          msisdn: '+9876543210',
        })
        .expect(403);
    });

    it('should bootstrap with matching MSISDN', async () => {
      const token = await deeplinkService.issueToken({
        flow: 'generate_qr',
        msisdn: '+1234567890',
        ttl: 3600,
      });

      const response = await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({
          token,
          msisdn: '+1234567890',
        })
        .expect(201);

      expect(response.body.flow).toBe('generate_qr');
    });

    it('should return 401 for invalid token', async () => {
      await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({ token: 'invalid.token.here' })
        .expect(401);
    });

    it('should reject missing token', async () => {
      await request(app.getHttpServer())
        .post('/whatsappFlow/bootstrap')
        .send({})
        .expect(400);
    });
  });

  describe('Flow state templates', () => {
    it('should return appropriate messages for all flows', async () => {
      const flows = ['insurance_attach', 'basket_open', 'generate_qr'] as const;

      for (const flow of flows) {
        const token = await deeplinkService.issueToken({
          flow,
          ttl: 3600,
        });

        const response = await request(app.getHttpServer())
          .post('/whatsappFlow/bootstrap')
          .send({ token })
          .expect(201);

        expect(response.body.flowState).toHaveProperty('type', 'text');
        expect(response.body.flowState).toHaveProperty('content');
        expect(typeof response.body.flowState.content).toBe('string');
        expect(response.body.flowState.content.length).toBeGreaterThan(0);
      }
    });
  });
});
