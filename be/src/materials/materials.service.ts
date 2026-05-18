import { Injectable } from '@nestjs/common';
import { CreateMaterialDto } from './dto/create-material.dto';
import { UpdateMaterialDto } from './dto/update-material.dto';
import { User } from '../users/entities/user.entity';

@Injectable()
export class MaterialsService {
  create(createMaterialDto: CreateMaterialDto, causer: User) {
    return 'This action adds a new material';
  }

  findAll() {
    return `This action returns all materials`;
  }

  findOne(id: number) {
    return `This action returns a #${id} material`;
  }

  update(id: number, updateMaterialDto: UpdateMaterialDto) {
    return `This action updates a #${id} material`;
  }

  remove(id: number, causer: User) {
    return `This action removes a #${id} material`;
  }
}
