import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export type RequestUser = { userId: string; email: string };

export const ReqUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest<{ user?: RequestUser }>();
    return req.user;
  },
);
