import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { AdminOrSupervisorGuard } from './admin-or-supervisor.guard';

function makeContext(user: { role?: string; systemAdmin?: boolean } | null): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ user: user ?? undefined }),
    }),
  } as unknown as ExecutionContext;
}

describe('AdminOrSupervisorGuard', () => {
  let guard: AdminOrSupervisorGuard;

  beforeEach(() => {
    guard = new AdminOrSupervisorGuard();
  });

  it('allows admin role', () => {
    expect(guard.canActivate(makeContext({ role: 'admin' }))).toBe(true);
  });

  it('allows supervisor role', () => {
    expect(guard.canActivate(makeContext({ role: 'supervisor' }))).toBe(true);
  });

  it('allows systemAdmin=true even when role is user', () => {
    expect(guard.canActivate(makeContext({ role: 'user', systemAdmin: true }))).toBe(true);
  });

  it('allows systemAdmin=true with no role', () => {
    expect(guard.canActivate(makeContext({ systemAdmin: true }))).toBe(true);
  });

  it('blocks user role', () => {
    expect(() => guard.canActivate(makeContext({ role: 'user' }))).toThrow(ForbiddenException);
  });

  it('blocks missing user', () => {
    expect(() => guard.canActivate(makeContext(null))).toThrow(ForbiddenException);
  });
});
