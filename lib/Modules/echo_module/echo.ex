defmodule Echo do
  use Servus.Module
  require Logger

  register(:TEST_ECHO)

  def startup do
    Logger.info("Echo module registered")
    # Return module state here
    []
  end

  react :BASIC_ECHO, args, client, state do
    Logger.info("Echo module called")
    %{result_code: :ok, value: {:value_String, args}}
  end

  @doc """
    Generic Error Handler
  """
  react _, _ = args, client, state do
    %{result_code: :error, errorMessage: nil, errorType: :ERROR_WRONGMETHOD}
  end
end
