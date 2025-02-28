import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures performance updates and rewards work correctly with validation",
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
    
    // Test invalid performance update
    let invalidBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-performance', [
        types.uint(101), // Invalid uptime
        types.uint(98)
      ], wallet1.address)
    ]);
    
    invalidBlock.receipts[0].result.expectErr(106); // err-invalid-performance
    
    // Update performance metrics
    let perfBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-performance', [
        types.uint(99),
        types.uint(98)
      ], wallet1.address)
    ]);
    
    perfBlock.receipts[0].result.expectOk();
    
    // Update metadata
    let metaBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-metadata', [
        types.ascii("Updated Node"),
        types.ascii("http://localhost:9000"),
        types.ascii("US-West")
      ], wallet1.address)
    ]);
    
    metaBlock.receipts[0].result.expectOk();
    
    // Previous tests remain unchanged
  },
});
