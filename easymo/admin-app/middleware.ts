import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const DEV_FALLBACK_ACTOR = process.env.NODE_ENV === 'production' 
  ? null 
  : (process.env.ADMIN_DEFAULT_ACTOR_ID ?? null);

export function middleware(request: NextRequest) {
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  let actorId = request.headers.get('x-actor-id')
    ?? request.cookies.get('admin_actor_id')?.value
    ?? ((process.env.NODE_ENV !== 'production') ? DEV_FALLBACK_ACTOR : null);

  if (!actorId) {
    return NextResponse.json(
      {
        error: 'unauthorized',
        message: 'Missing x-actor-id header. Provide a valid admin actor identifier.',
      },
      { status: 401 },
    );
  }

  if (!UUID_REGEX.test(actorId)) {
    return NextResponse.json(
      {
        error: 'invalid_actor_id',
        message: 'Actor identifier must be a UUID.',
      },
      { status: 400 },
    );
  }

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-actor-id', actorId);

  const response = NextResponse.next({ request: { headers: requestHeaders } });

  const isProduction = process.env.NODE_ENV === 'production';
  const shouldSetCookie = isProduction || !request.cookies.get('admin_actor_id');

  if (shouldSetCookie) {
    response.cookies.set('admin_actor_id', actorId, {
      httpOnly: isProduction,
      secure: isProduction,
      sameSite: 'lax',
      path: '/',
    });
  }

  return response;
}

export const config = {
  matcher: ['/api/:path*'],
};
