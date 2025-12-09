# ==============================================================================
# Makefile for Asian Barometer Crosswalk Extension
#
# Targets:
#   make extend       - Run full crosswalk extension pipeline
#   make nlp          - Run only Python NLP matching
#   make fuzzy        - Run only R fuzzy matching
#   make inventory    - Create variable inventory
#   make install-deps - Install Python dependencies
#   make clean        - Clean generated files (with confirmation)
#   make help         - Show this help
# ==============================================================================

.PHONY: all extend nlp fuzzy inventory install-deps clean help

# Default target
all: extend

# Project directories
PROJECT_ROOT := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_ROOT)/scripts
DOCS_DIR := $(PROJECT_ROOT)/docs

# Commands (can be overridden)
PYTHON := python3
RSCRIPT := Rscript

# Key input/output files
INVENTORY := $(DOCS_DIR)/q_variables_by_wave.csv
FUZZY_OUTPUT := $(DOCS_DIR)/high_similarity_pairs.csv
NLP_OUTPUT := $(DOCS_DIR)/crosswalk_nlp_enhanced.csv
EXPANDED_CROSSWALK := $(PROJECT_ROOT)/abs_harmonization_crosswalk_EXPANDED.csv

# ==============================================================================
# Main targets
# ==============================================================================

help:
	@echo "Asian Barometer Crosswalk Extension Pipeline"
	@echo ""
	@echo "Available targets:"
	@echo "  make extend       - Run full crosswalk extension pipeline"
	@echo "  make nlp          - Run only Python NLP matching"
	@echo "  make fuzzy        - Run only R fuzzy matching"
	@echo "  make inventory    - Create variable inventory"
	@echo "  make install-deps - Install Python dependencies"
	@echo "  make clean-logs   - Clean log files"
	@echo "  make check-deps   - Check if dependencies are installed"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Pipeline order: inventory -> fuzzy -> nlp -> expand"

# Full pipeline
extend: check-deps inventory fuzzy nlp expand
	@echo ""
	@echo "========================================"
	@echo "Crosswalk extension pipeline complete!"
	@echo "========================================"
	@echo ""
	@echo "Generated files:"
	@ls -la $(DOCS_DIR)/high_similarity_pairs.csv 2>/dev/null || true
	@ls -la $(DOCS_DIR)/crosswalk_nlp_enhanced.csv 2>/dev/null || true
	@ls -la $(EXPANDED_CROSSWALK) 2>/dev/null || true

# Variable inventory (Step 1)
inventory: $(INVENTORY)
$(INVENTORY):
	@echo "Creating variable inventory..."
	@$(RSCRIPT) $(SCRIPTS_DIR)/00_create_variable_inventory.R

# Fuzzy matching (Step 2) - depends on inventory
fuzzy: $(FUZZY_OUTPUT)
$(FUZZY_OUTPUT): $(INVENTORY)
	@echo "Running fuzzy label matching..."
	@$(RSCRIPT) $(SCRIPTS_DIR)/01_fuzzy_label_matching.R

# NLP matching (Step 3) - depends on inventory
nlp: $(NLP_OUTPUT)
$(NLP_OUTPUT): $(INVENTORY)
	@echo "Running NLP-based semantic matching..."
	@$(PYTHON) $(SCRIPTS_DIR)/02_advanced_nlp_matching.py

# Crosswalk expansion (Step 4) - depends on fuzzy and nlp
expand: $(EXPANDED_CROSSWALK)
$(EXPANDED_CROSSWALK): $(FUZZY_OUTPUT) $(NLP_OUTPUT)
	@echo "Running intelligent crosswalk expansion..."
	@$(RSCRIPT) $(SCRIPTS_DIR)/03_expand_crosswalk_intelligently.R

# ==============================================================================
# Utility targets
# ==============================================================================

# Install Python dependencies
install-deps:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	@echo -n "  R: " && ($(RSCRIPT) --version 2>&1 | head -1) || echo "NOT FOUND"
	@echo -n "  Python: " && $(PYTHON) --version 2>&1 || echo "NOT FOUND"
	@echo -n "  sentence-transformers: " && \
		($(PYTHON) -c "import sentence_transformers; print('OK')" 2>/dev/null || echo "NOT INSTALLED")
	@echo ""

# Clean log files
clean-logs:
	@echo "Cleaning log files..."
	rm -f $(PROJECT_ROOT)/logs/*.log

# Force rebuild (touch source to trigger make)
rebuild: clean-outputs
	@echo "Triggering rebuild..."
	touch $(INVENTORY) 2>/dev/null || true

# Clean generated outputs (with confirmation)
clean-outputs:
	@echo "This will remove generated output files."
	@echo "Press Ctrl+C to cancel, Enter to continue..."
	@read dummy
	rm -f $(FUZZY_OUTPUT)
	rm -f $(NLP_OUTPUT)
	rm -f $(EXPANDED_CROSSWALK)
	rm -f $(DOCS_DIR)/concept_clusters.csv
	rm -f $(DOCS_DIR)/crosswalk_expanded_automated.csv
	rm -f $(DOCS_DIR)/semantic_similarity_pairs.csv
