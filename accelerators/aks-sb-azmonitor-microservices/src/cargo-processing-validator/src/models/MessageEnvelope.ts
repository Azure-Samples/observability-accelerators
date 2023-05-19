import { Cargo } from './Cargo';

export interface MessageEnvelope {
  operationId: string;
  data: Cargo;
}
