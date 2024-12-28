import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures node registration works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('orbit_node', 'register-node', [
        types.ascii("Test Node"),
        types.ascii("http://localhost:8000"),
        types.ascii("US-East")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify node info
    let nodeInfo = chain.mineBlock([
      Tx.contractCall('orbit_node', 'get-node-info', [
        types.principal(wallet1.address)
      ], deployer.address)
    ]);
    
    let result = nodeInfo.receipts[0].result;
    assertEquals(result.expectSome()['status'], types.ascii("active"));
  },
});

Clarinet.test({
  name: "Ensures status updates work correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // First register node
    let block = chain.mineBlock([
      Tx.contractCall('orbit_node', 'register-node', [
        types.ascii("Test Node"),
        types.ascii("http://localhost:8000"),
        types.ascii("US-East")
      ], wallet1.address)
    ]);
    
    // Then update status
    let updateBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'update-status', [
        types.ascii("inactive")
      ], wallet1.address)
    ]);
    
    updateBlock.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Ensures staking works correctly",
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
    
    // Add stake
    let stakeBlock = chain.mineBlock([
      Tx.contractCall('orbit_node', 'add-stake', [
        types.uint(500)
      ], wallet1.address)
    ]);
    
    stakeBlock.receipts[0].result.expectOk();
    
    // Verify total staked amount
    let totalStaked = chain.mineBlock([
      Tx.contractCall('orbit_node', 'get-total-staked', [], wallet1.address)
    ]);
    
    totalStaked.receipts[0].result.expectOk().expectUint(1500); // minimum-stake + added stake
  },
});