defmodule WeftspunStudio do
  @moduledoc """
  Studio core. The first root of the strangler fig in RFD 0019.

  The browser client still owns the studio logic. This application
  takes one responsibility at a time. Phase 1 holds the model
  inventory from RFD 0016 and checks the client catalog against it.

  See `WeftspunStudio.Inventory` for the data and
  `WeftspunStudio.JsCatalog` for the parity check.
  """

  defdelegate models, to: WeftspunStudio.Inventory, as: :all
  defdelegate active_models, to: WeftspunStudio.Inventory, as: :active
end
