pragma solidity >=0.5.12;

import "ds-test/test.sol";

import "../actions.sol";
import "../proxy.sol";
import "../registry.sol";

import "tinlake/core/test/mock/shelf.sol";
import "tinlake/core/test/mock/pile.sol";
import "tinlake/core/test/mock/desk.sol";

contract RegistryTest is DSTest {
    ProxyRegistry registry;
    Title title;
    ProxyFactory factory;

    Proxy proxy;

    // Core Contracts Mocks
    ShelfMock shelf;
    PileMock pile;
    DeskMock desk;

    Actions actions;

    function buildProxy() public returns(Proxy) {
        title = new Title("Tinlake", "TLO");
        factory = new ProxyFactory(address(title));
        title.rely(address(factory));
        registry = new ProxyRegistry(address(factory));

        address payable proxyAddr = registry.build();
        return Proxy(proxyAddr);
    }

    function setUp() public {
        proxy = buildProxy();

        shelf = new ShelfMock();
        pile = new PileMock();
        desk = new DeskMock();

        actions = new Actions();
    }
    // --- Checks ---
    function checkBorrow(uint loan, address deposit, uint balance) public {
        assertEq(shelf.loan(), loan);
        assertEq(shelf.depositCalls(), 1);
        assertEq(shelf.usr(), address(proxy));

        assertEq(desk.callsBalance(), 1);

        assertEq(pile.callsWithdraw(), 1);
        assertEq(pile.loan(), loan);
        assertEq(pile.wad(), balance);
        assertEq(pile.usr(), deposit);
    }

    function checkRepay(uint loan, address deposit, uint debt) public {
        assertEq(pile.callsRepay(), 1);
        assertEq(pile.loan(), loan);
        assertEq(pile.wad(), debt);

        assertEq(shelf.releaseCalls(), 1);
        assertEq(shelf.loan(), loan);
        assertEq(shelf.usr(), deposit);

        assertEq(desk.callsBalance(), 1);
    }


    function init() public returns(uint, address, uint)  {
        uint loan = 42;
        address deposit = address(1234);
        uint balance = 1000;

        return (loan, deposit, balance);
}

    // --- Tests ---
    function testBorrow() public {
        (uint loan, address deposit, uint balance) = init();
        pile.setBalanceReturn(balance);

        bytes memory data = abi.encodeWithSignature("borrow(address,address,address,uint256,address)", address(desk), address(pile), address(shelf), loan, deposit);
        proxy.execute(address(actions), data);
        checkBorrow(loan, deposit, balance);
    }

    function testRepay() public {
        (uint loan, address deposit, uint debt) = init();

        bytes memory data = abi.encodeWithSignature("repay(address,address,address,uint256,uint256,address)", address(desk), address(pile), address(shelf), loan, debt, deposit);
        proxy.execute(address(actions), data);
        checkRepay(loan, deposit, debt);
    }

    function testClose() public {
        (uint loan, address deposit, uint debt) = init();
        pile.setDebtOfReturn(debt);

        bytes memory data = abi.encodeWithSignature("close(address,address,address,uint256,address)", address(desk), address(pile), address(shelf), loan, deposit);
        proxy.execute(address(actions), data);

        assertEq(pile.callsCollect(), 1);
        checkRepay(loan, deposit, debt);
    }
}
