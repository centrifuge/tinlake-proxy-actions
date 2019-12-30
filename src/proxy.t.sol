pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./proxy.sol";

contract proxyTest is DSTest {
    proxy proxy;

    function setUp() public {
        proxy = new proxy();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
