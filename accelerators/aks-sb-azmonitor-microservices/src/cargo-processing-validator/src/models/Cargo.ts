export interface Cargo {
  timestamp: Date;
  id: string;
  product: {
    name: string;
    quantity: number;
  };
  port: {
    source: string;
    destination: string;
  };
  demandDates: {
    start: Date;
    end: Date;
  };
}
