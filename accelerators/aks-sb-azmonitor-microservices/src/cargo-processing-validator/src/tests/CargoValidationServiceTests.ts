import { expect } from 'chai';
import { CargoValidationService } from '../services/CargoValidationService';
import { Cargo } from '../models/Cargo';
import 'mocha';
import { ValidatedCargo } from '../models/ValidatedCargo';

describe('validation tests', () => {
  let cargo: Cargo;

  beforeEach(() => {
    cargo = {
      timestamp: new Date(),
      id: '',
      product: {
        name: 'product',
        quantity: 1,
      },
      port: {
        source: 'sourcePort',
        destination: 'destinationPort',
      },
      // initialize demand dates as today
      demandDates: {
        start: new Date(),
        end: new Date(),
      },
    };
  });

  it('should return valid', () => {
    // arrange
    const cargoValidationService: CargoValidationService =
      new CargoValidationService();

    // ensure demand dates are valid
    cargo.demandDates.start.setDate(cargo.demandDates.start.getDate() + 1);
    cargo.demandDates.end.setDate(cargo.demandDates.end.getDate() + 2);

    // act
    const result: ValidatedCargo =
      cargoValidationService.validateCargo(cargo);

    // assert
    expect(result.valid).to.be.true;
    expect(result.errorMessage).to.be.null;
  });

  it('should return invalid - dates must be in future', () => {
    // arrange
    const cargoValidationService: CargoValidationService =
      new CargoValidationService();

    // ensure demand dates are valid
    cargo.demandDates.start.setDate(cargo.demandDates.start.getDate() - 2);
    cargo.demandDates.end.setDate(cargo.demandDates.end.getDate() - 1);

    // act
    const result: ValidatedCargo =
      cargoValidationService.validateCargo(cargo);

    // assert
    expect(result.valid).to.be.false;
    expect(result.errorMessage).to.equal(
      'Start and end dates must be in future.'
    );
  });
  it('should return invalid - start date cannot be 60 days in future', () => {
    // arrange
    const cargoValidationService: CargoValidationService =
      new CargoValidationService();

    // ensure demand dates are invalid
    cargo.demandDates.start.setDate(cargo.demandDates.start.getDate() + 65);
    cargo.demandDates.end.setDate(cargo.demandDates.end.getDate() + 68);

    // act
    const result: ValidatedCargo =
      cargoValidationService.validateCargo(cargo);

    // assert
    expect(result.valid).to.be.false;
    expect(result.errorMessage).to.equal(
      'Start date cannot be more than 60 days in future.'
    );
  });
  it('should return invalid - date range cannot exceed 30 days', () => {
    // arrange
    const cargoValidationService: CargoValidationService =
      new CargoValidationService();

    // ensure demand dates are invalid
    cargo.demandDates.start.setDate(cargo.demandDates.start.getDate() + 30);
    cargo.demandDates.end.setDate(cargo.demandDates.end.getDate() + 90);

    // act
    const result: ValidatedCargo =
      cargoValidationService.validateCargo(cargo);

    // assert
    expect(result.valid).to.be.false;
    expect(result.errorMessage).to.equal(
      'Range between start and end dates cannot exceed 30 days.'
    );
  });
  it('should return invalid - end date must be after start date', () => {
    // arrange
    const cargoValidationService: CargoValidationService =
      new CargoValidationService();

    // ensure demand dates are invalid
    cargo.demandDates.start.setDate(cargo.demandDates.start.getDate() + 2);
    cargo.demandDates.end.setDate(cargo.demandDates.end.getDate() + 1);

    // act
    const result: ValidatedCargo =
      cargoValidationService.validateCargo(cargo);

    // assert
    expect(result.valid).to.be.false;
    expect(result.errorMessage).to.equal(
      'End date must be after start date.'
    );
  });
});
