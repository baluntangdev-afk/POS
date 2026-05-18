import { QueryDeepPartialEntity } from 'typeorm';

export class EntityHelper {
  static toPartialEntity<T>(entity: T): QueryDeepPartialEntity<T> {
    return entity as QueryDeepPartialEntity<T>;
  }

  static toIdEntity<T>(id: string | number): T {
    return { id } as unknown as T;
  }
}
