import { Injectable, UnauthorizedException, GoneException, ForbiddenException } from '@nestjs/common';
import { signJwt, verifyJwt } from '../../common/crypto';
import * as jose from 'jose';
import { env } from '../../common/env';
import { IssueTokenDto } from './dto/issue-token.dto';
import { ResolveTokenDto } from './dto/resolve-token.dto';
import { SupportedFlow } from './dto/issue-token.dto';

interface DeeplinkPayload {
  flow: SupportedFlow;
  payload?: Record<string, unknown>;
  msisdn?: string;
}

@Injectable()
export class DeeplinkService {
  async issueToken(data: IssueTokenDto): Promise<string> {
    const payload: DeeplinkPayload = {
      flow: data.flow,
      payload: data.payload,
    };

    if (data.msisdn) {
      payload.msisdn = data.msisdn;
    }

    const token = await signJwt(payload, env.deeplinkSecret, data.ttl);
    return token;
  }

  async resolveToken(data: ResolveTokenDto): Promise<{ flow: SupportedFlow; payload?: Record<string, unknown> }> {
    try {
      const decoded = await verifyJwt(data.token, env.deeplinkSecret);
      
      const flow = decoded.flow as SupportedFlow;
      const payload = decoded.payload as Record<string, unknown> | undefined;
      const boundMsisdn = decoded.msisdn as string | undefined;

      // Check MSISDN binding if token has bound MSISDN
      if (boundMsisdn) {
        if (!data.msisdn) {
          throw new ForbiddenException('MSISDN required');
        }

        if (boundMsisdn !== data.msisdn) {
          throw new ForbiddenException('MSISDN mismatch');
        }
      }

      return {
        flow,
        payload,
      };
    } catch (error: any) {
      // Check if token is expired
      if (error instanceof jose.errors.JWTExpired) {
        throw new GoneException('Token expired');
      }
      
      // Handle MSISDN mismatch
      if (error instanceof ForbiddenException) {
        throw error;
      }

      // Any other verification error
      throw new UnauthorizedException('Invalid token');
    }
  }
}
