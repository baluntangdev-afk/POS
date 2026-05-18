import { Controller } from '@nestjs/common';
import { UomService } from './uom.service';

@Controller('uom')
export class UomController {
  constructor(private readonly uomService: UomService) {}
}
