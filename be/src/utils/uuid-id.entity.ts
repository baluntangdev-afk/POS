import { PrimaryColumn, BeforeInsert } from 'typeorm';
import { uuidv7 } from 'uuidv7';

/**
 * Reusable base for entities that use a UUID v7 primary key (time-ordered, app-generated).
 * Extend this class and add @Entity() on the child; do not redefine id or generateId.
 */
export abstract class UuidIdEntity {
  @PrimaryColumn({ type: 'uuid', name: 'id' })
  id: string;

  @BeforeInsert()
  generateId(): void {
    if (!this.id) {
      this.id = uuidv7();
    }
  }
}
