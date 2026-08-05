# SPDX-License-Identifier: MIT

# Every port gets a Mox mock. RFD 0054 records the rule: the suite
# mocks each side, and the planning documents stay real.
#
# A mock is defined from the behaviour, thus a port that gains a
# callback breaks its mock at compile time. That is the point of
# defining the port as a behaviour rather than a convention.
Mox.defmock(WeftspunCMS.MockPlanner, for: WeftspunCMS.Core.Ports.Planner)
Mox.defmock(WeftspunCMS.MockCatalogSource, for: WeftspunCMS.Core.Ports.CatalogSource)
Mox.defmock(WeftspunCMS.MockOwnedAssetSource, for: WeftspunCMS.Core.Ports.OwnedAssetSource)
Mox.defmock(WeftspunCMS.MockJobStore, for: WeftspunCMS.Core.Ports.JobStore)
Mox.defmock(WeftspunCMS.MockAssetStore, for: WeftspunCMS.Core.Ports.AssetStore)
