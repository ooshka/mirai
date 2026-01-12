# frozen_string_literal: true

RSpec.describe "Health" do
  it "returns ok" do
    get "/health"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq({ "ok" => true})
  end
end
