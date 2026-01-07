-include .env
export

.PHONY: all clean install build test snapshot format deploy-account deploy-paymaster fund-paymaster send-op view-balance help

# -----------------------
#  🎨 COLORS & CONFIG
# -----------------------
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
BLUE   := $(shell tput -Txterm setaf 4)
RESET  := $(shell tput -Txterm sgr0)

# Default Network (Sepolia)
RPC_URL ?= $(SEPOLIA_RPC_URL)
SENDER ?= $(OWNER_ADDRESS)

# -----------------------
#  🛠️  ESSENTIALS
# -----------------------
all: clean install build

help:
	@echo ""
	@echo "${BLUE}====== 🚀 FOUNDRY AA TOOLKIT ====== ${RESET}"
	@echo ""
	@echo "${YELLOW}Deployment & Execution:${RESET}"
	@echo "  ${GREEN}make send-op${RESET}        : 🪄 Run the 'God Script' (Deploy + Paymaster + UserOp)"
	@echo "  ${GREEN}make reuse-fix${RESET}      : 🔧 Run the Reuse Script (Saves Gas, uses existing contracts)"
	@echo ""
	@echo "${YELLOW}Utilities:${RESET}"
	@echo "  ${GREEN}make view-balance${RESET}   : 💰 Check ETH balance of OWNER_ADDRESS"
	@echo "  ${GREEN}make format${RESET}         : 🧹 Format Solidity code"
	@echo "  ${GREEN}make clean${RESET}          : 🗑️  Clean artifacts"
	@echo "  ${GREEN}make build${RESET}          : 🏗️  Compile contracts"
	@echo ""

# -----------------------
#  CORE COMMANDS
# -----------------------

# 1. THE MAIN FIX (New Deploy + Fund + Send)
send-op:
	@echo "${BLUE}Running Self-Contained Fix Script...${RESET}"
	forge script script/SendUserOpWithPaymaster.s.sol:SendUserOpWithPaymaster --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# 2. THE REUSE FIX (If you already deployed and just want to retry sending)
reuse-fix:
	@echo "${BLUE}Running Reuse Script (Saving Gas)...${RESET}"
	forge script script/ReuseFix.s.sol:ReuseFix --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast -vvvv

# 3. UTILS
view-balance:
	@echo "${YELLOW}Checking Balance for: $(SENDER)${RESET}"
	cast balance $(SENDER) --rpc-url $(RPC_URL) --ether

# -----------------------
#  STANDARD FOUNDRY
# -----------------------
build:
	@echo "${BLUE}Building contracts...${RESET}"
	forge build

clean:
	@echo "${YELLOW}Cleaning artifacts...${RESET}"
	forge clean

install:
	forge install foundry-rs/forge-std@v1.8.2 --no-commit
	forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit
	forge install eth-infinitism/account-abstraction@v0.7.0 --no-commit

test:
	forge test -vvv

format:
	forge fmt