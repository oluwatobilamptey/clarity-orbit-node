import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Previous tests remain unchanged

Clarinet.test({
  name: "Ensures performance updates and rewards work correctly",
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
    
    // Update performance metrics
    let perfBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-performance', [
        types.uint(9900), // 99% uptime
        types.uint(98)    // 98% performance score
      ], wallet1.address)
    ]);
    
    perfBlock.receipts[0].result.expectOk();
    
    // Mine blocks to pass cooldown
    chain.mineEmptyBlockUntil(perfBlock.height + 145);
    
    // Try claiming rewards
    let rewardBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'claim-rewards', [], wallet1.address)
    ]);
    
    rewardBlock.receipts[0].result.expectOk();
  },
});
