import { Controller } from '@nestjs/common';
import { TaxCategoriesService } from './tax-categories.service';

@Controller('tax-categories')
export class TaxCategoriesController {
  constructor(private readonly taxCategoriesService: TaxCategoriesService) {}
}
