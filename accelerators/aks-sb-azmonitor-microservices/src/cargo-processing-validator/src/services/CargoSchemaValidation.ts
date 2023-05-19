import Ajv from 'ajv';
import * as cargoEnvelopeSchema from '../schemas/cargo-envelope-schema.json';

export class CargoSchemaValidation {
  private ajv: Ajv;
  private validator;

  constructor() {
    this.ajv = new Ajv();
    this.validator = this.ajv.compile(cargoEnvelopeSchema);
  }

  validate(cargo: string) {
    console.log('Validating cargo schema');
    const results = this.validator(cargo);
    if (results) {
      return { isValid: true };
    } else {
      return {
        isValid: false,
        message: JSON.stringify(this.validator.errors),
      };
    }
  }
}
