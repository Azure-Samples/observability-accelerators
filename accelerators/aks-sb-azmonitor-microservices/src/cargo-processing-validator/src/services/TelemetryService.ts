export class TelemetryService {
  public static generateNewContext(): { operationId: string, operationParentId: string } {
    return {
      operationId: TelemetryService.generateOpenTelemetryRequestId(),
      operationParentId: TelemetryService.generateOpenTelemetryDependencyId(),
    };
  }
  
  public static generateOpenTelemetryId(length: number): string {
    // must satisfy regex for ids - https://github.com/open-telemetry/opentelemetry-js/blob/0f178d1e2e9b3aed81789820944452c153543198/api/src/trace/spancontext-utils.ts#L22
    const chars: string = 'abcdef1234567890';
    const randomArray: string[] = Array.from(
      { length: length },
      () => chars[Math.floor(Math.random() * chars.length)]
    );
    return randomArray.join('');
  }

  public static generateOpenTelemetryRequestId(): string {
    return TelemetryService.generateOpenTelemetryId(32);
  }

  public static generateOpenTelemetryDependencyId(): string {
    return TelemetryService.generateOpenTelemetryId(16);
  }

  public static returnElapsedMillisecondsSinceStart(start: bigint, end: bigint): number {
    const elapsedNanoSeconds: number = Number(end - start);
    const elapsedMilliseconds = elapsedNanoSeconds / 1000000;
    return elapsedMilliseconds;
  }
}
