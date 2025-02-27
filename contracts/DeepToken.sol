// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DeepToken is ERC20, Ownable, Pausable {
    // 토큰 발행 관련 변수
    uint256 public maxSupply; // 최대 발행량
    uint256 public tokenPrice; // 토큰 가격 (1 ETH = tokenPrice 토큰)
    uint256 public totalMinted; // 현재까지 발행된 토큰 수량

    // 이벤트
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensMinted(address indexed to, uint256 amount);
    event TokenPriceUpdated(uint256 newPrice);

    // 생성자: 토큰 이름, 심볼, 초기 발행량, 최대 발행량, 토큰 가격 설정
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 _maxSupply,
        uint256 _tokenPrice
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(initialSupply <= _maxSupply, "Initial supply exceeds max supply");
        maxSupply = _maxSupply;
        tokenPrice = _tokenPrice;
        _mint(msg.sender, initialSupply);
        totalMinted = initialSupply;
    }

    // 토큰 구매 함수 (ETH로 토큰 구매)
    function buyTokens() external payable whenNotPaused {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint256 tokensToBuy = (msg.value * tokenPrice) / 1 ether;
        require(totalMinted + tokensToBuy <= maxSupply, "Exceeds max supply");

        _mint(msg.sender, tokensToBuy);
        totalMinted += tokensToBuy;
        emit TokensPurchased(msg.sender, tokensToBuy);
    }

    // 토큰 수로 토큰 구매 (토큰 수량을 입력하면 필요한 ETH 계산)
    function buyTokensWithAmount(uint256 tokenAmount) external payable whenNotPaused {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        uint256 requiredETH = (tokenAmount * 1 ether) / tokenPrice;
        require(msg.value >= requiredETH, "Insufficient ETH sent");

        require(totalMinted + tokenAmount <= maxSupply, "Exceeds max supply");

        _mint(msg.sender, tokenAmount);
        totalMinted += tokenAmount;

        // 남은 ETH 환불
        if (msg.value > requiredETH) {
            payable(msg.sender).transfer(msg.value - requiredETH);
        }

        emit TokensPurchased(msg.sender, tokenAmount);
    }

    // 관리자만 토큰 발행 가능 (추가 발행)
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(totalMinted + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
        totalMinted += amount;
        emit TokensMinted(to, amount);
    }

    // 토큰 가격 업데이트 (관리자만 가능)
    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be greater than 0");
        tokenPrice = newPrice;
        emit TokenPriceUpdated(newPrice);
    }

    // 컨트랙트 일시 정지 (관리자만 가능)
    function pause() external onlyOwner {
        _pause();
    }

    // 컨트랙트 재개 (관리자만 가능)
    function unpause() external onlyOwner {
        _unpause();
    }

    // 컨트랙트에 모인 ETH 출금 (관리자만 가능)
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    // 현재까지 발행된 토큰 수량 조회
    function getTotalMinted() external view returns (uint256) {
        return totalMinted;
    }

    // 현재 토큰 가격 조회
    function getTokenPrice() external view returns (uint256) {
        return tokenPrice;
    }

    // 컨트랙트의 ETH 잔고 조회
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 특정 주소의 토큰 잔고 조회
    function getTokenBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    // 토근 소각
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}