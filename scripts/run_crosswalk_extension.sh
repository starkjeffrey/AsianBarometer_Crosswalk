#!/bin/bash
# ==============================================================================
# run_crosswalk_extension.sh
# Automated pipeline for extending the Asian Barometer crosswalk
#
# This script orchestrates:
#   1. Variable inventory creation (R)
#   2. Fuzzy label matching (R)
#   3. NLP-based semantic matching (Python)
#   4. Intelligent crosswalk expansion (R)
#
# Usage: ./scripts/run_crosswalk_extension.sh [--skip-inventory] [--python-only]
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Log file
LOG_FILE="$PROJECT_ROOT/logs/crosswalk_extension_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$PROJECT_ROOT/logs"

# Helper functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}==================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}==================================================${NC}" | tee -a "$LOG_FILE"
}

# Parse command-line arguments
SKIP_INVENTORY=false
PYTHON_ONLY=false
R_ONLY=false
INSTALL_DEPS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-inventory)
            SKIP_INVENTORY=true
            shift
            ;;
        --python-only)
            PYTHON_ONLY=true
            shift
            ;;
        --r-only)
            R_ONLY=true
            shift
            ;;
        --install-deps)
            INSTALL_DEPS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-inventory   Skip the variable inventory step (use existing docs/q_variables_by_wave.csv)"
            echo "  --python-only      Only run the Python NLP matching step"
            echo "  --r-only           Only run the R fuzzy matching steps"
            echo "  --install-deps     Install Python dependencies before running"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Change to project root
cd "$PROJECT_ROOT"

log_section "CROSSWALK EXTENSION PIPELINE"
log "Project root: $PROJECT_ROOT"
log "Log file: $LOG_FILE"

# ==============================================================================
# Check dependencies
# ==============================================================================
log_section "CHECKING DEPENDENCIES"

# Check for R
R_AVAILABLE=false
if command -v Rscript &> /dev/null; then
    R_VERSION=$(Rscript --version 2>&1 | head -1)
    log "R found: $R_VERSION"
    R_AVAILABLE=true
else
    log_warning "R/Rscript not found. R-based steps will be skipped."
    log_warning "Install R to run the full pipeline: https://cran.r-project.org/"
fi

# Check for Python
PYTHON_AVAILABLE=false
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log "Python found: $PYTHON_VERSION"
    PYTHON_AVAILABLE=true
else
    log_warning "Python3 not found. Python-based steps will be skipped."
fi

# Install Python dependencies if requested
if [ "$INSTALL_DEPS" = true ] && [ "$PYTHON_AVAILABLE" = true ]; then
    log "Installing Python dependencies..."
    pip install -r "$PROJECT_ROOT/requirements.txt" 2>&1 | tee -a "$LOG_FILE"
fi

# Check Python NLP dependencies
if [ "$PYTHON_AVAILABLE" = true ]; then
    if python3 -c "import sentence_transformers" 2>/dev/null; then
        log "Python NLP dependencies: OK"
    else
        log_warning "Python NLP dependencies missing. Run with --install-deps or: pip install -r requirements.txt"
        if [ "$PYTHON_ONLY" = true ]; then
            log_error "Cannot proceed with --python-only without NLP dependencies"
            exit 1
        fi
    fi
fi

# Check for required input file
if [ ! -f "$PROJECT_ROOT/docs/q_variables_by_wave.csv" ]; then
    if [ "$SKIP_INVENTORY" = true ]; then
        log_error "docs/q_variables_by_wave.csv not found! Cannot skip inventory step."
        exit 1
    fi
else
    log "Variable inventory found: docs/q_variables_by_wave.csv"
fi

# ==============================================================================
# Step 1: Create Variable Inventory (R)
# ==============================================================================
if [ "$PYTHON_ONLY" = false ] && [ "$SKIP_INVENTORY" = false ] && [ "$R_AVAILABLE" = true ]; then
    log_section "STEP 1: CREATING VARIABLE INVENTORY"

    if Rscript "$SCRIPT_DIR/00_create_variable_inventory.R" 2>&1 | tee -a "$LOG_FILE"; then
        log "Variable inventory created successfully"
    else
        log_error "Variable inventory creation failed"
        exit 1
    fi
elif [ "$SKIP_INVENTORY" = true ]; then
    log "Skipping inventory step (--skip-inventory)"
elif [ "$R_AVAILABLE" = false ]; then
    log_warning "Skipping inventory step (R not available)"
fi

# ==============================================================================
# Step 2: Fuzzy Label Matching (R)
# ==============================================================================
if [ "$PYTHON_ONLY" = false ] && [ "$R_AVAILABLE" = true ]; then
    log_section "STEP 2: FUZZY LABEL MATCHING (R)"

    if Rscript "$SCRIPT_DIR/01_fuzzy_label_matching.R" 2>&1 | tee -a "$LOG_FILE"; then
        log "Fuzzy label matching completed successfully"
    else
        log_error "Fuzzy label matching failed"
        exit 1
    fi
elif [ "$R_AVAILABLE" = false ]; then
    log_warning "Skipping fuzzy matching step (R not available)"
fi

# ==============================================================================
# Step 3: NLP-Based Semantic Matching (Python)
# ==============================================================================
if [ "$R_ONLY" = false ] && [ "$PYTHON_AVAILABLE" = true ]; then
    log_section "STEP 3: NLP-BASED SEMANTIC MATCHING (Python)"

    # Check if dependencies are available
    if python3 -c "import sentence_transformers" 2>/dev/null; then
        if python3 "$SCRIPT_DIR/02_advanced_nlp_matching.py" 2>&1 | tee -a "$LOG_FILE"; then
            log "NLP-based matching completed successfully"
        else
            log_error "NLP-based matching failed"
            exit 1
        fi
    else
        log_warning "Skipping NLP matching (dependencies not installed)"
        log_warning "Run: pip install -r requirements.txt"
    fi
elif [ "$PYTHON_AVAILABLE" = false ]; then
    log_warning "Skipping NLP matching step (Python not available)"
fi

# ==============================================================================
# Step 4: Intelligent Crosswalk Expansion (R)
# ==============================================================================
if [ "$PYTHON_ONLY" = false ] && [ "$R_AVAILABLE" = true ]; then
    log_section "STEP 4: INTELLIGENT CROSSWALK EXPANSION"

    if Rscript "$SCRIPT_DIR/03_expand_crosswalk_intelligently.R" 2>&1 | tee -a "$LOG_FILE"; then
        log "Crosswalk expansion completed successfully"
    else
        log_error "Crosswalk expansion failed"
        exit 1
    fi
elif [ "$R_AVAILABLE" = false ]; then
    log_warning "Skipping crosswalk expansion step (R not available)"
fi

# ==============================================================================
# Summary
# ==============================================================================
log_section "PIPELINE COMPLETE"

log "Generated/updated files:"
if [ -f "$PROJECT_ROOT/docs/q_variables_by_wave.csv" ]; then
    log "  - docs/q_variables_by_wave.csv (variable inventory)"
fi
if [ -f "$PROJECT_ROOT/docs/high_similarity_pairs.csv" ]; then
    log "  - docs/high_similarity_pairs.csv (fuzzy matches)"
fi
if [ -f "$PROJECT_ROOT/docs/crosswalk_nlp_enhanced.csv" ]; then
    log "  - docs/crosswalk_nlp_enhanced.csv (NLP-enhanced crosswalk)"
fi
if [ -f "$PROJECT_ROOT/docs/semantic_similarity_pairs.csv" ]; then
    log "  - docs/semantic_similarity_pairs.csv (semantic matches)"
fi
if [ -f "$PROJECT_ROOT/abs_harmonization_crosswalk_EXPANDED.csv" ]; then
    log "  - abs_harmonization_crosswalk_EXPANDED.csv (expanded crosswalk)"
fi

log ""
log "Full log saved to: $LOG_FILE"
log ""
log "Next steps:"
log "  1. Review the generated files in docs/"
log "  2. Validate high-similarity pairs for accuracy"
log "  3. Merge approved concepts into abs_harmonization_crosswalk_MASTER.csv"
log "  4. Run scale detection: Rscript scripts/05_detect_scale_types.R"
