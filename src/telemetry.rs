use opentelemetry::global;

use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use opentelemetry_sdk::{trace as sdktrace, Resource};
use tracing::subscriber::set_global_default;
use tracing_opentelemetry::layer;
use tracing_subscriber::{layer::SubscriberExt, EnvFilter, Registry};

pub fn init_telemetry() {
    // Create an OTLP exporter
    let exporter = opentelemetry_otlp::new_exporter()
        .tonic()
        .with_endpoint("http://localhost:4317");

    // Create a tracer provider
    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(exporter)
        .with_trace_config(sdktrace::config().with_resource(Resource::new(vec![
            opentelemetry::KeyValue::new("service.name", "api-rest-rust"),
        ])))
        .install_batch(opentelemetry_sdk::runtime::Tokio)
        .expect("Failed to install OTLP tracer");

    // Create a meter provider
    let meter_provider = opentelemetry_sdk::metrics::SdkMeterProvider::builder().build();

    // Set the global tracer and meter providers
    global::set_tracer_provider(tracer.provider().unwrap());
    global::set_meter_provider(meter_provider);
    global::set_text_map_propagator(TraceContextPropagator::new());

    // Create a tracing subscriber
    let subscriber = Registry::default()
        .with(EnvFilter::new("info"))
        .with(layer().with_tracer(tracer));

    set_global_default(subscriber).expect("Failed to set global default subscriber");
}
