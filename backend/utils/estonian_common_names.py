# Mapping of scientific names (lowercase) to Estonian common names
ESTONIAN_NAME_MAP = {
    'taraxacum officinale': 'Võilill',
    'bellis perennis': 'Kirikakar',
    'tulipa gesneriana': 'Tulp',
    'primula veris': 'Nurmenukk',
    'convallaria majalis': 'Maikelluke',
    'leucanthemum vulgare': 'Härjasilm',
    'trifolium repens': 'Valge ristik',
    'campanula patula': 'Harilik kellukas'
}

def get_estonian_name(scientific_name: str, fallback_common_names=None):
    if not scientific_name:
        return None
    name = ESTONIAN_NAME_MAP.get(scientific_name.lower())
    if name:
        return name
    # If not mapped, try to pick any existing Estonian-looking common name (with umlauts) from provided list
    if fallback_common_names:
        for cn in fallback_common_names:
            if any(ch in cn.lower() for ch in ['õ','ä','ö','ü']):
                return cn
    return None
