#!/usr/bin/env node
// Prebuild and CI guard: assert-no-service-role-in-client.mjs
// Purpose: Fails the build if server-only secret names are exposed via NEXT_PUBLIC_* env variables.
// This prevents accidental exposure of service role keys and other sensitive secrets.

const forbiddenNames = [
  'SERVICE_ROLE',
  'SERVICE_KEY',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SUPABASE_SERVICE_KEY',
  'ADMIN_TOKEN',
  'EASYMO_ADMIN_TOKEN',
  'SECRET_KEY',
  'PRIVATE_KEY',
  'DATABASE_URL',
  'DB_PASSWORD',
  'MOMO_API_KEY',
  'MOMO_SECRET',
];

// Check for forbidden patterns in environment variables
let foundViolation = false;

const looksLikeServiceRoleKey = (rawValue) => {
  if (!rawValue) return false;
  const value = String(rawValue).trim().replace(/^['"]|['"]$/g, '');
  if (value.length < 80) return false;

  const upperValue = value.toUpperCase();
  if (!upperValue.startsWith('EYJ')) return false;

  const jwtParts = value.split('.');
  if (jwtParts.length < 3) return false;

  return jwtParts.every((part) => /^[A-Z0-9_-]+$/i.test(part));
};

// Check process.env for NEXT_PUBLIC_ prefixed variables
for (const [key, value] of Object.entries(process.env)) {
  if (key.startsWith('NEXT_PUBLIC_') || key.startsWith('VITE_')) {
    // Check if the key or value contains forbidden names
    const upperKey = key.toUpperCase();

    for (const forbidden of forbiddenNames) {
      if (upperKey.includes(forbidden)) {
        console.error(`❌ SECURITY VIOLATION: Public env variable "${key}" contains forbidden name "${forbidden}"`);
        foundViolation = true;
      }

      // Check if value looks like it might contain a service role key
      if (forbidden.includes('SERVICE') && looksLikeServiceRoleKey(value)) {
        console.error(`❌ SECURITY VIOLATION: Public env variable "${key}" appears to contain a service role key`);
        foundViolation = true;
      }
    }
  }
}

// Also check .env files if they exist
import { readFileSync, existsSync } from 'fs';
import { resolve } from 'path';

const envFiles = ['.env', '.env.local', '.env.production'];

for (const envFile of envFiles) {
  const envPath = resolve(process.cwd(), envFile);
  if (existsSync(envPath)) {
    const content = readFileSync(envPath, 'utf-8');
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (!line || line.startsWith('#')) continue;
      
      const match = line.match(/^(NEXT_PUBLIC_|VITE_)([^=]+)=(.*)/);
      if (match) {
        const [, prefix, name, value] = match;
        const fullKey = prefix + name;
        const upperKey = fullKey.toUpperCase();

        for (const forbidden of forbiddenNames) {
          if (upperKey.includes(forbidden)) {
            console.error(`❌ SECURITY VIOLATION in ${envFile}:${i + 1}: Public env variable "${fullKey}" contains forbidden name "${forbidden}"`);
            foundViolation = true;
          }

          if (forbidden.includes('SERVICE') && looksLikeServiceRoleKey(value)) {
            console.error(`❌ SECURITY VIOLATION in ${envFile}:${i + 1}: Public env variable "${fullKey}" appears to contain a service role key`);
            foundViolation = true;
          }
        }
      }
    }
  }
}

if (foundViolation) {
  console.error('\n❌ Build failed: Server-only secrets detected in client-side environment variables.');
  console.error('⚠️  Remove sensitive values from NEXT_PUBLIC_* and VITE_* variables.\n');
  process.exit(1);
}

console.log('✅ No service role or sensitive keys detected in client-side environment variables.');
process.exit(0);
