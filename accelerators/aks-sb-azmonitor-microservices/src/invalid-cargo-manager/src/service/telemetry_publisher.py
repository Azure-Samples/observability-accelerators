"""Class used to create and publish telemetry entities
"""

from app_config import LOGGING_APP_NAME
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace.samplers import AlwaysOnSampler
from opencensus.trace.tracer import Tracer
from opencensus.trace.span import SpanKind
from opencensus.trace.propagation.text_format import TextFormatPropagator


class TelemetryPublisher: #pylint: disable=too-few-public-methods
    """Class used to create and publish telemetry entities
    """

    def callback_function(self, envelope):
        envelope.tags['ai.cloud.role'] = LOGGING_APP_NAME

        # Check to see if the private.name attribute is set
        # And use it to set the name field of the telemetry item
        base_data = envelope.data['baseData']
        private_name = base_data['properties'].get('private.name')
        if private_name:
            # Remove the callback.name property from the telemetry item
            base_data['properties']['private.name']=None
            if base_data.name == '':
                base_data.name = private_name
        return True

    def create_tracer(self, telemetry_operation_id, telemetry_operation_parent_id):
        # Create tracer with parent set to the incoming item from cargo-processing-validator
        extracted_context = TextFormatPropagator().from_carrier(carrier={"opencensus-trace-traceid": telemetry_operation_id, "opencensus-trace-spanid": telemetry_operation_parent_id})
        app_insights_exporter=AzureExporter()
        tracer = Tracer(exporter=app_insights_exporter, sampler=AlwaysOnSampler(), span_context=extracted_context)
        app_insights_exporter.add_telemetry_processor(self.callback_function)
        return tracer

    def create_process_message_request_span(self, tracer, span_name, subscription_name):
        request_span = tracer.start_span(name=span_name)
        # Setting span kind to server causes the span to generate a request
        request_span.span_kind = SpanKind.SERVER
        request_span.add_attribute("http.url", "sb://{}".format(subscription_name))
        # AzureExporter doesn't only sets the name field for HTTP spans
        # Pass the span name as an attribute so that the callback function can set the name field
        request_span.add_attribute("private.name", span_name)
        return request_span

    def create_dependency_span(self, tracer, span_name):
        dependency_span = tracer.start_span(name=span_name)
        # Setting span kind to client causes the span to generate a dependency
        dependency_span.span_kind = SpanKind.CLIENT
        return dependency_span

    def create_operations_queue_send_dependency_span(self, tracer, span_name):
        dependency_span = self.create_dependency_span(tracer, span_name)
        # Set dependency type property
        dependency_span.add_attribute("component", "Queue Message | servicebus")
        # Set dependency target property (xxx://<TARGET>/xx)
        dependency_span.add_attribute("http.url", "sb://operations")
        return dependency_span

    def create_validated_cargo_topic_dependency_span(self, tracer, span_name):
        dependency_span = self.create_dependency_span(tracer, span_name)
        dependency_span.add_attribute("component", "Azure Service Bus")
        dependency_span.add_attribute("http.url", "sb://validated-cargo")
        return dependency_span

    def create_cosmos_db_store_dependency_span(self, tracer, span_name):
        dependency_span = self.create_dependency_span(tracer, span_name)
        dependency_span.add_attribute("component", "Azure DocumentDB")
        return dependency_span