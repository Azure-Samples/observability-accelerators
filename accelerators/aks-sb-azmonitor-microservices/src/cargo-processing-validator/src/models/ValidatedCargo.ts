import { Cargo } from './Cargo';

export interface ValidatedCargo extends Cargo {
  valid: boolean;
  errorMessage: string | null;
}
