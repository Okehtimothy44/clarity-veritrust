import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that only contract owner can add manufacturers",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;

        let block = chain.mineBlock([
            // Owner adding manufacturer should succeed
            Tx.contractCall('veritrust', 'add-manufacturer', [
                types.principal(wallet1.address)
            ], deployer.address),
            // Non-owner adding manufacturer should fail
            Tx.contractCall('veritrust', 'add-manufacturer', [
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(100));
    }
});

Clarinet.test({
    name: "Ensure product registration works correctly",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        
        // First add manufacturer
        let setup = chain.mineBlock([
            Tx.contractCall('veritrust', 'add-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address)
        ]);

        setup.receipts[0].result.expectOk();

        // Test product registration
        let block = chain.mineBlock([
            Tx.contractCall('veritrust', 'register-product', [
                types.ascii("PROD123"),
                types.ascii("Authentic Product XYZ")
            ], manufacturer.address)
        ]);

        block.receipts[0].result.expectOk();

        // Verify product
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('veritrust', 'verify-product', [
                types.ascii("PROD123")
            ], deployer.address)
        ]);

        verifyBlock.receipts[0].result.expectOk();
    }
});

Clarinet.test({
    name: "Ensure product ownership transfer works",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const manufacturer = accounts.get('wallet_1')!;
        const newOwner = accounts.get('wallet_2')!;
        
        // Setup manufacturer and product
        let setup = chain.mineBlock([
            Tx.contractCall('veritrust', 'add-manufacturer', [
                types.principal(manufacturer.address)
            ], deployer.address),
            Tx.contractCall('veritrust', 'register-product', [
                types.ascii("PROD123"),
                types.ascii("Authentic Product XYZ")
            ], manufacturer.address)
        ]);

        // Transfer ownership
        let block = chain.mineBlock([
            Tx.contractCall('veritrust', 'transfer-ownership', [
                types.ascii("PROD123"),
                types.principal(newOwner.address)
            ], manufacturer.address)
        ]);

        block.receipts[0].result.expectOk();

        // Verify new owner
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('veritrust', 'get-product-owner', [
                types.ascii("PROD123")
            ], deployer.address)
        ]);

        assertEquals(
            verifyBlock.receipts[0].result.expectOk(),
            newOwner.address
        );
    }
});