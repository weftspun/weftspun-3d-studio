# RFD 0078: An H2O/FoundationDB game-state server

**State:** moved

Developed in its own repository,
[weftspun/h2o-bench-tpcc](https://github.com/weftspun/h2o-bench-tpcc)
(`rfd/0022-weftspun-studio-consumer.md`,
[PR #1](https://github.com/weftspun/h2o-bench-tpcc/pull/1)),
per the user's own direction: `weftspun_studio` is a backend
service, not the state database, so the open question belongs
beside the project that would host the state, not here.

## Related

RFD 0077 gives the CDN question that raised this one. RFD 0061 and
RFD 0062 name `multiplayer-fabric-godot` as the asset-streaming
transport's other consumer, and a candidate home for this server.
