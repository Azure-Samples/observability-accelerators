import { Cargo } from '../models/Cargo';
import { ValidatedCargo } from '../models/ValidatedCargo';
import { DateTime, Duration } from 'luxon';
import { TelemetryService } from './TelemetryService';
import * as appInsights from 'applicationinsights';

export class CargoValidationService {
  private telemetryClient: appInsights.TelemetryClient;

  constructor(telemetryClient : appInsights.TelemetryClient) {
   this.telemetryClient = telemetryClient;
  }
  async validateCargo(cargo: Cargo): Promise<ValidatedCargo> {
    console.log('Validating cargo properties');

    let isValid: boolean = true;
    let errorMessage: string | null = null;

    // start, end, and timestamp are epoch times on the incoming message
    const start: DateTime = DateTime.fromJSDate(
      new Date(cargo.demandDates.start)
    );
    const end: DateTime = DateTime.fromJSDate(new Date(cargo.demandDates.end));
    const now: DateTime = DateTime.now();
    const diffBetweenStartAndNow: Duration = start.diff(now, 'days');
    const diffBetweenStartAndEnd: Duration = end.diff(start, 'days');

    // validate start and end are in future
    if (start <= now || end <= now) {
      isValid = false;
      errorMessage = 'Start and end dates must be in future.';
    }

    // validate start is not more than 60 days in future
    if (diffBetweenStartAndNow.days > 60) {
      isValid = false;
      errorMessage = 'Start date cannot be more than 60 days in future.';
    }

    // validate range is not greater than 30 days
    if (diffBetweenStartAndEnd.days > 30) {
      isValid = false;
      errorMessage = 'Range between start and end dates cannot exceed 30 days.';
    }

    // validate end date is after start date
    if (diffBetweenStartAndEnd.days < 0) {
      isValid = false;
      errorMessage = 'End date must be after start date.';
    }

    // validate destination port
    const destinationPortOk = await this.checkDestinationPort(cargo.port.destination);
    if (!destinationPortOk) {
      isValid = false;
      errorMessage = 'Rejected by destination port.';
    }

    console.log(`Valid - ${isValid}, Error message - ${errorMessage}`);
    const validatedMessageBody: ValidatedCargo = {
      ...cargo,
      valid: isValid,
      errorMessage,
    };
    return validatedMessageBody;
  }

  private async executeDependency<T>(
    dependency: () => Promise<T>,
    dependencyTarget: string,
    dependencyTypeName: string,
    properties?: { [key: string]: any; }
  ): Promise<T> {
    const dependencyId: string = TelemetryService.generateOpenTelemetryDependencyId();
    const dependencyStart: bigint = process.hrtime.bigint();

    const dependencyName = `${dependencyTypeName} ${dependencyTarget}`

    try {
      // Make the dependency call
      const result = await (dependency());

      // track dependencies in application insights, ensure they are properly parented
      const dependencyEnd: bigint = process.hrtime.bigint();
      this.telemetryClient.trackDependency({
        target: dependencyTarget,
        name: dependencyName,
        data: '',
        duration: TelemetryService.returnElapsedMillisecondsSinceStart(
          dependencyStart,
          dependencyEnd
        ),
        resultCode: 200,
        success: true,
        dependencyTypeName,
        id: dependencyId,
        properties,
      });

      return result;
    } catch (error) {
      const dependencyEnd: bigint = process.hrtime.bigint();

      // track dependencies in application insights, ensure they are properly parented
      this.telemetryClient.trackDependency({
        target: dependencyTarget,
        name: dependencyName,
        data: '',
        duration: TelemetryService.returnElapsedMillisecondsSinceStart(
          dependencyStart,
          dependencyEnd
        ),
        resultCode: 500,
        success: false,
        dependencyTypeName,
        id: dependencyId,
        properties,
      });

      throw error;
    }
  }

  private async checkDestinationPort(name: string) : Promise<boolean> {
    const _internal = async (name : string) : Promise<boolean> => {
      // This method is used to mock out calling an HTTP service at the destination port
      // The intent is to show how telemetry can be used to track variations in behavior
      switch (name) {
        case "slow-port":
          // Simulate an issue with the port response times by adding a delay
          await this.sleep(2000)
          return true

        default:
          await this.sleep(100)
          return true;
      }
    }
    return await this.executeDependency<boolean>(
      () => _internal(name),
      name,
      "destination-port-check",
    )
  }

  private sleep(time: number) {
    return new Promise(resolve => setTimeout(resolve, time));
  }
}
