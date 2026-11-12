# BaseDB Validation

Use OpenTofu >= 1.11 for mocked-provider tests. Tests perform no OCI operations and need no OCI credentials.

```sh
tofu init -backend=false
tofu test
```

The three end-to-end examples also contain their own `tests/composition.tftest.hcl`; run `tofu test` from each example directory to exercise its complete composition. Cross-region tests use separate regional mocks and verify target-region standby IP discovery and two DRG/RPC stacks.

Tests verify mutually exclusive primary/standby resource creation, target IDs and private IP outputs, primary requirements, standby requirements and supported Data Guard transport validation. Mocked APIs do not prove live provisioning, regional availability, database login or Data Guard health. Run and record those checks separately before claiming deployment verification.

See [examples](../examples/README.md), [support](../SUPPORT.md) and [license](../LICENSE).
