import { Injectable } from '@nestjs/common';
import { CreateUserPermissionDto } from './dto/create-user-permission.dto';
import { UpdateUserPermissionDto } from './dto/update-user-permission.dto';

@Injectable()
export class UserPermissionsService {
  create(createUserPermissionDto: CreateUserPermissionDto) {
    return 'This action adds a new userPermission';
  }

  findAll() {
    return `This action returns all userPermissions`;
  }

  findOne(id: number) {
    return `This action returns a #${id} userPermission`;
  }

  update(id: number, updateUserPermissionDto: UpdateUserPermissionDto) {
    return `This action updates a #${id} userPermission`;
  }

  remove(id: number) {
    return `This action removes a #${id} userPermission`;
  }
}
