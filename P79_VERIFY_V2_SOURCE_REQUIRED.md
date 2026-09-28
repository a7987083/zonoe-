# Verify v2 source requirement

The supplied integration guide defines the endpoint and security properties but does not define the exact Protocol v2 canonical string construction, signed fields, or HMAC input ordering.

To avoid a false implementation, P79 will not activate the new auth path until the validated implementation of `ZONDylibVerify.*` / its canonical-HMAC contract is imported.

Required source facts:

- canonical payload field list and order
- timestamp representation
- nonce representation
- body/query encoding rules
- HMAC algorithm and output encoding
- request header/body placement of signature fields
- Runtime Config fields consumed by Verify

Production secrets must remain outside the repository.
