#!/usr/bin/env python3
"""
Advanced NLP-Based Variable Matching for Asian Barometer Crosswalk
Uses semantic embeddings and clustering for intelligent variable harmonization
"""

import pandas as pd
import numpy as np
import re
from pathlib import Path
from typing import List, Dict, Tuple
import warnings
warnings.filterwarnings('ignore')

# Print initial message
print("\n" + "="*70)
print("ADVANCED NLP-BASED LABEL MATCHING")
print("="*70 + "\n")

# Check and import required packages
required_packages = {
    'sentence_transformers': 'sentence-transformers',
    'sklearn': 'scikit-learn',
    'scipy': 'scipy',
}

missing_packages = []
for module_name, pip_name in required_packages.items():
    try:
        __import__(module_name)
    except ImportError:
        missing_packages.append(pip_name)

if missing_packages:
    print("⚠️  Missing required packages. Install with:")
    print(f"   pip install {' '.join(missing_packages)}\n")
    print("Continuing with basic matching only...\n")
    USE_ADVANCED = False
else:
    from sentence_transformers import SentenceTransformer
    from sklearn.cluster import AgglomerativeClustering, DBSCAN
    from sklearn.metrics.pairwise import cosine_similarity
    from scipy.cluster.hierarchy import dendrogram, linkage
    USE_ADVANCED = True
    print("✓ All NLP packages loaded successfully\n")

# ---------------------
# 1. Load Data
# ---------------------
print("Loading variable inventory...")
project_root = Path(__file__).parent.parent
q_vars_file = project_root / "docs" / "q_variables_by_wave.csv"

if not q_vars_file.exists():
    print(f"❌ Error: {q_vars_file} not found!")
    print("   Run scripts/00_create_variable_inventory.R first")
    exit(1)

q_vars = pd.read_csv(q_vars_file)
print(f"  - Total q-variables: {len(q_vars):,}")
print(f"  - Unique variables: {q_vars['variable'].nunique():,}")
print(f"  - Waves: {', '.join(q_vars['wave'].unique())}\n")

# ---------------------
# 2. Text Preprocessing
# ---------------------
print("Preprocessing labels...")

def clean_label(label: str) -> str:
    """Clean and standardize variable labels"""
    if pd.isna(label):
        return ""

    # Convert to string and lowercase
    label = str(label).lower()

    # Remove common prefixes
    label = re.sub(r'^q[0-9]+\.?\s*', '', label)  # Remove q123. prefix
    label = re.sub(r'^[0-9]+\.?\s*', '', label)    # Remove 123. prefix

    # Remove annotations
    label = re.sub(r'\(hk:.*?\)', '', label)      # Remove HK notes
    label = re.sub(r'\[.*?\]', '', label)          # Remove [bracketed] text
    label = re.sub(r'\(.*?country.*?\)', '', label, flags=re.IGNORECASE)  # Remove country names

    # Clean up whitespace and punctuation
    label = re.sub(r'[^\w\s]', ' ', label)        # Replace punctuation with space
    label = ' '.join(label.split())                # Remove extra whitespace

    return label.strip()

# Apply cleaning
q_vars['label_clean'] = q_vars['label'].apply(clean_label)

# Remove rows with empty labels
q_vars = q_vars[q_vars['label_clean'].str.len() > 0].copy()

print(f"  ✓ {len(q_vars):,} variables with valid labels\n")

# ---------------------
# 3. Create Unique Variable List
# ---------------------
print("Creating unique variable-label combinations...")

# Group by variable to get cross-wave information
unique_vars = q_vars.groupby('variable').agg({
    'label_clean': 'first',
    'label': 'first',
    'wave': lambda x: ', '.join(sorted(x.unique())),
    'value_labels_sample': 'first'
}).reset_index()

unique_vars['n_waves'] = unique_vars['wave'].str.split(',').str.len()

print(f"  - Unique labeled variables: {len(unique_vars):,}\n")

# ---------------------
# 4. Semantic Embedding-Based Matching
# ---------------------
if USE_ADVANCED:
    print("Computing semantic embeddings...")
    print("  (Using sentence-transformers for meaning-based matching)")

    # Load pre-trained model (optimized for semantic similarity)
    model = SentenceTransformer('all-MiniLM-L6-v2')

    # Generate embeddings for all labels
    labels_list = unique_vars['label_clean'].tolist()
    embeddings = model.encode(labels_list, show_progress_bar=True)

    print(f"  ✓ Generated embeddings: {embeddings.shape}\n")

    # ---------------------
    # 5. Compute Semantic Similarity
    # ---------------------
    print("Computing pairwise semantic similarity...")

    # Compute cosine similarity between all pairs
    similarity_matrix = cosine_similarity(embeddings)

    # Create similarity dataframe
    similarity_df_list = []

    for i in range(len(unique_vars)):
        var1 = unique_vars.iloc[i]['variable']
        label1 = unique_vars.iloc[i]['label_clean']

        # Get similarities with all other variables
        sims = similarity_matrix[i]

        # Keep only high-similarity pairs (> 0.7) excluding self
        high_sim_indices = np.where((sims > 0.7) & (np.arange(len(sims)) != i))[0]

        for j in high_sim_indices:
            var2 = unique_vars.iloc[j]['variable']
            label2 = unique_vars.iloc[j]['label_clean']
            sim_score = sims[j]

            similarity_df_list.append({
                'var1': var1,
                'var2': var2,
                'label1': label1[:100],
                'label2': label2[:100],
                'similarity': sim_score,
                'waves1': unique_vars.iloc[i]['wave'],
                'waves2': unique_vars.iloc[j]['wave']
            })

    similar_vars = pd.DataFrame(similarity_df_list)
    similar_vars = similar_vars.sort_values('similarity', ascending=False)

    # Remove duplicate pairs (keep only var1 < var2 alphabetically)
    similar_vars['var_pair'] = similar_vars.apply(
        lambda row: tuple(sorted([row['var1'], row['var2']])), axis=1
    )
    similar_vars = similar_vars.drop_duplicates(subset=['var_pair'])

    print(f"  ✓ Found {len(similar_vars):,} high-similarity pairs (>0.7)\n")

    # ---------------------
    # 6. Hierarchical Clustering
    # ---------------------
    print("Performing hierarchical clustering...")

    # Use Ward linkage for clustering
    # Distance = 1 - similarity
    distance_matrix = 1 - similarity_matrix

    # Perform hierarchical clustering
    clustering = AgglomerativeClustering(
        n_clusters=None,
        distance_threshold=0.3,  # Distance threshold for cluster formation
        linkage='average',
        metric='precomputed'
    )

    cluster_labels = clustering.fit_predict(distance_matrix)

    # Add cluster labels to unique_vars
    unique_vars['cluster_id'] = cluster_labels

    print(f"  ✓ Identified {unique_vars['cluster_id'].nunique():,} concept clusters\n")

    # ---------------------
    # 7. Create Concept Groups
    # ---------------------
    print("Creating concept groups...")

    # Group variables by cluster
    concept_groups = unique_vars.groupby('cluster_id').agg({
        'variable': lambda x: ', '.join(sorted(x)),
        'label_clean': 'first',
        'n_waves': 'sum',
        'wave': lambda x: ' | '.join(x)
    }).reset_index()

    concept_groups['n_variables'] = concept_groups['variable'].str.split(',').str.len()
    concept_groups = concept_groups[concept_groups['n_variables'] > 1]  # Only multi-variable clusters

    concept_groups = concept_groups.sort_values('n_variables', ascending=False)

    print(f"  ✓ Created {len(concept_groups):,} multi-variable concept groups\n")

else:
    print("⚠️  Advanced NLP features unavailable - using basic matching\n")
    similar_vars = pd.DataFrame()
    concept_groups = pd.DataFrame()

# ---------------------
# 8. Domain Classification
# ---------------------
print("Classifying variables by domain...")

# Enhanced domain keywords
domain_patterns = {
    'trust_institutional': r'trust.*(?:government|court|parliament|police|military|civil\sservice|executive|president|official|institution)',
    'trust_interpersonal': r'trust.*(?:people|neighbor|relative|friend|stranger|other)',
    'economic_evaluation': r'(?:economic|economy|livelihood|financial|income).*(?:condition|situation|better|worse|good|bad)',
    'corruption': r'corrupt|bribe|bribery',
    'democracy_support': r'democra(?:cy|tic).*(?:prefer|support|suitable|best|import)',
    'democracy_satisfaction': r'satisf.*democra',
    'democracy_level': r'(?:level|extent|degree|how\smuch).*democra',
    'freedom_expression': r'(?:free|freedom).*(?:speak|say|express|opinion|think)',
    'freedom_assembly': r'(?:free|freedom).*(?:join|organize|association|assembly|group)',
    'equality': r'equal|inequality|treat.*equal',
    'participation': r'participat|take\spart|involve|engage',
    'political_efficacy': r'(?:influence|say|voice|matter).*government|people\slike\sme',
    'political_interest': r'interest.*politic',
    'voting': r'vote|election|ballot',
    'media': r'media|newspaper|television|tv|radio|internet|news',
    'civil_society': r'ngo|civil\ssociety|association|organization',
    'governance_quality': r'government.*(?:respond|capab|effect|perform)',
    'rule_of_law': r'law.*(?:enforce|obey|break|above)',
    'accountability': r'accountab|check|monitor|responsib',
    'legislature': r'parliament|congress|legislature|assembly',
    'judiciary': r'court|judge|judicial|legal\ssystem',
    'local_government': r'local.*government|municipal|village|community',
    'covid': r'covid|coronavirus|pandemic|vaccin',
    'authoritarianism': r'strong\sleader|military.*govern|expert.*decide',
    'traditional_values': r'tradition|moral|religious|family.*government',
    'identity': r'ethnic|religion|race|nationality|citizen',
    'social_capital': r'neighbor|contact|help|support',
}

def classify_domain(label: str) -> List[str]:
    """Classify label into domain categories"""
    if not label:
        return ['other']

    matches = []
    for domain, pattern in domain_patterns.items():
        if re.search(pattern, label, re.IGNORECASE):
            matches.append(domain)

    return matches if matches else ['other']

unique_vars['domains'] = unique_vars['label_clean'].apply(classify_domain)
unique_vars['primary_domain'] = unique_vars['domains'].apply(lambda x: x[0])
unique_vars['all_domains'] = unique_vars['domains'].apply(lambda x: '; '.join(x))

print(f"  ✓ Domain classification complete\n")

# Domain distribution
domain_counts = unique_vars['primary_domain'].value_counts()
print("  Top domains:")
for domain, count in domain_counts.head(10).items():
    print(f"    - {domain}: {count}")
print()

# ---------------------
# 9. Export Results
# ---------------------
print("Exporting results...")

output_dir = project_root / "docs"

# 1. Enhanced crosswalk with embeddings
crosswalk_enhanced = q_vars.pivot_table(
    index='variable',
    columns='wave',
    values='label',
    aggfunc='first'
).reset_index()

# Merge with domain classification
crosswalk_enhanced = crosswalk_enhanced.merge(
    unique_vars[['variable', 'primary_domain', 'all_domains', 'n_waves']],
    on='variable',
    how='left'
)

# Merge with cluster info if available
if USE_ADVANCED:
    crosswalk_enhanced = crosswalk_enhanced.merge(
        unique_vars[['variable', 'cluster_id']],
        on='variable',
        how='left'
    )

# Sort by domain and waves
crosswalk_enhanced = crosswalk_enhanced.sort_values(
    ['primary_domain', 'n_waves'],
    ascending=[True, False]
)

crosswalk_enhanced.to_csv(output_dir / "crosswalk_nlp_enhanced.csv", index=False)
print(f"  ✓ crosswalk_nlp_enhanced.csv ({len(crosswalk_enhanced)} variables)")

# 2. Semantic similarity pairs (if available)
if USE_ADVANCED and len(similar_vars) > 0:
    similar_vars.to_csv(output_dir / "semantic_similarity_pairs.csv", index=False)
    print(f"  ✓ semantic_similarity_pairs.csv ({len(similar_vars)} pairs)")

# 3. Concept clusters (if available)
if USE_ADVANCED and len(concept_groups) > 0:
    concept_groups.to_csv(output_dir / "concept_clusters_nlp.csv", index=False)
    print(f"  ✓ concept_clusters_nlp.csv ({len(concept_groups)} clusters)")

# 4. Domain-sorted detailed view
detailed_view = unique_vars.copy()
detailed_view = detailed_view.sort_values(['primary_domain', 'n_waves'], ascending=[True, False])
detailed_view.to_csv(output_dir / "variables_by_domain_detailed.csv", index=False)
print(f"  ✓ variables_by_domain_detailed.csv ({len(detailed_view)} variables)")

# 5. Summary statistics
summary = pd.DataFrame({
    'metric': [
        'Total q-variables',
        'Unique variables',
        'Variables in 2+ waves',
        'Variables in all 6 waves',
        'Semantic similarity pairs (>0.7)' if USE_ADVANCED else 'N/A',
        'Concept clusters identified' if USE_ADVANCED else 'N/A',
        'Domains identified',
    ],
    'count': [
        len(q_vars),
        len(unique_vars),
        len(unique_vars[unique_vars['n_waves'] >= 2]),
        len(unique_vars[unique_vars['n_waves'] == 6]),
        len(similar_vars) if USE_ADVANCED else 0,
        unique_vars['cluster_id'].nunique() if USE_ADVANCED else 0,
        len(domain_counts),
    ]
})

summary.to_csv(output_dir / "nlp_matching_summary.csv", index=False)
print(f"  ✓ nlp_matching_summary.csv")

# ---------------------
# 10. Final Summary
# ---------------------
print("\n" + "="*70)
print("NLP MATCHING COMPLETE")
print("="*70 + "\n")

print(summary.to_string(index=False))

print("\n📊 GENERATED FILES:")
print("  1. crosswalk_nlp_enhanced.csv - Main crosswalk with domain classification")
if USE_ADVANCED:
    print("  2. semantic_similarity_pairs.csv - Semantically similar variables")
    print("  3. concept_clusters_nlp.csv - Automatically clustered concepts")
print("  4. variables_by_domain_detailed.csv - Domain-sorted detailed view")
print("  5. nlp_matching_summary.csv - Summary statistics")

print("\n🚀 NEXT STEPS:")
print("  1. Review semantic_similarity_pairs.csv for high-quality matches")
print("  2. Use concept_clusters_nlp.csv to create concept names")
print("  3. Validate automated domain classifications")
print("  4. Merge with existing abs_harmonization_crosswalk.csv")
print("  5. Create scale harmonization rules")

print("\n✓ Advanced NLP analysis complete!\n")
