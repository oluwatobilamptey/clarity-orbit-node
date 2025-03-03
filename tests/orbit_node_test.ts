[Previous imports and setup remain unchanged...]

Clarinet.test({
  name: "Ensures reward claiming works with cooldown period",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Register node
    let block = chain.mineBlock([
      Tx.contractCall('orbit_node', 'register-node', [
        types.ascii("Test Node"),
        types.ascii("http://localhost:8000"),
        types.ascii("US-East")
      ], wallet1.address)
    ]);
    
    // Update performance
    let perfBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-performance', [
        types.uint(99),
        types.uint(98)
      ], wallet1.address)
    ]);
    
    // Try to claim rewards before cooldown
    let earlyClaimBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'claim-rewards', [], wallet1.address)
    ]);
    
    earlyClaimBlock.receipts[0].result.expectErr(105); // err-cooldown-active
    
    // Mine blocks to pass cooldown
    for (let i = 0; i < 144; i++) {
      chain.mineBlock([]);
    }
    
    // Claim rewards after cooldown
    let claimBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'claim-rewards', [], wallet1.address)
    ]);
    
    claimBlock.receipts[0].result.expectOk();
  },
});

[Previous tests remain unchanged]
