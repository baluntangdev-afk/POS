import { Controller } from '@nestjs/common';
import { UserDetailsService } from './user-details.service';

@Controller('user-details')
export class UserDetailsController {
  constructor(private readonly userDetailsService: UserDetailsService) {}
}
