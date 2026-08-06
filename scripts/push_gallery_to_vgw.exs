#!/usr/bin/env elixir
# Pushes proof assets to the versitygw instance colocated in the Fly
# toplevel's own container, over its loopback-only S3 API. RFD 0058
# already names versitygw as the user's existing setup. RFD 0073
# records why this replaced the Tigris/S3 plan for now: no custom
# HTTP layer to build, no new cloud credentials, real and verified
# locally before this session's clock ran out.
#
# Run this from inside the same container versitygw runs in (a
# release task, or `flyctl ssh console` on the deployed machine),
# since the port never leaves 127.0.0.1 on purpose.
#
# Usage:
#   VGW_ACCESS_KEY=... VGW_SECRET_KEY=... elixir scripts/push_gallery_to_vgw.exs

Mix.install([
  {:ex_aws, "~> 2.5"},
  {:ex_aws_s3, "~> 2.5"},
  {:hackney, "~> 1.20"},
  {:sweet_xml, "~> 0.7"}
])

Application.put_all_env(
  ex_aws: [
    access_key_id: System.fetch_env!("VGW_ACCESS_KEY"),
    secret_access_key: System.fetch_env!("VGW_SECRET_KEY"),
    s3: [
      scheme: "http://",
      host: "127.0.0.1",
      port: 10000,
      region: "us-east-1"
    ]
  ]
)

files = [
  {"apps/usd_viewer_app/public/usd/sample_billboard.png", "sample_billboard.png", "image/png"},
  {"apps/usd_viewer_app/public/usd/sample_billboard.usda", "sample_billboard.usda", "model/vnd.usd"},
  {"apps/usd_viewer_app/public/usd/sample_billboard.usdz", "sample_billboard.usdz", "model/vnd.usdz+zip"}
]

for {path, key, content_type} <- files do
  body = File.read!(path)

  case ExAws.S3.put_object("gallery", key, body, content_type: content_type) |> ExAws.request() do
    {:ok, %{status_code: 200}} ->
      IO.puts("ok   #{key} (#{byte_size(body)} bytes)")

    other ->
      IO.puts("FAIL #{key}: #{inspect(other)}")
  end
end
