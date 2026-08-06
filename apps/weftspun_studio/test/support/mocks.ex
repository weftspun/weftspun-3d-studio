# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee

# Mox doubles for the driven ports. The job ports reach the DGX
# backend and run model work, so tests never use a real adapter.
Mox.defmock(WeftspunStudio.JobSourceMock, for: WeftspunStudio.Ports.JobSource)
Mox.defmock(WeftspunStudio.JobSinkMock, for: WeftspunStudio.Ports.JobSink)
Mox.defmock(WeftspunStudio.CatalogSourceMock, for: WeftspunStudio.Ports.CatalogSource)
Mox.defmock(WeftspunStudio.FactSinkMock, for: WeftspunStudio.Ports.FactSink)
Mox.defmock(WeftspunStudio.GallerySourceMock, for: WeftspunStudio.Ports.GallerySource)
