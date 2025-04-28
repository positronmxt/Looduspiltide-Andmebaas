# Code Organization Rules for Nature Photo Database

## Core Rule: 300-Line Maximum

The primary rule for this codebase is that **no file should exceed 300 lines of code**. This rule applies to all source code files including Python backend files, JavaScript/React frontend files, CSS, and any other code files.

## Language Rule: Estonian Localization

All user-facing text throughout the application should be in Estonian. This includes:
- UI elements (buttons, labels, headings)
- Error messages
- Tooltips and hints
- Placeholder text
- Notifications

Code documentation and comments may be in English for international development collaboration.

## General Organization Principles

1. **Single Responsibility Principle**: Each file should have a clear, single responsibility.
2. **Modular Design**: Break down large components into smaller, reusable modules.
3. **Logical Grouping**: Group related functionality into directories with clear naming conventions.

## Backend Organization (Python)

1. **API Endpoint Organization**:
   - Organize endpoints by resource/domain in separate router files
   - Example: `photo_routes.py`, `species_routes.py`, etc.
   - Main application file should only register routers and configure the app

2. **Models Organization**:
   - Split large model files into domain-specific files
   - Example: `photo_models.py`, `species_models.py`
   - Use a common `base_models.py` for shared model components

3. **Service Layer**:
   - Implement a service layer to handle business logic
   - Create service files for each domain: `photo_service.py`, `species_service.py`
   - Keep database operations separate from API logic

4. **Utility Functions**:
   - Create a `utils` directory with specific utility modules
   - Example: `image_utils.py`, `validation_utils.py`

## Frontend Organization (React)

1. **Component Structure**:
   - Break down large components into smaller, focused components
   - Create directory for each major feature with its related components
   - Example: `/components/species-verification/SpeciesForm.js`, `.../SpeciesResult.js`

2. **Code Splitting**:
   - Separate logic, markup, and styles
   - Use custom hooks for reusable logic
   - Extract large functions to utility files

3. **State Management**:
   - Distribute state management across appropriate levels
   - Create separate files for complex reducers, context providers, etc.

## Naming Conventions

1. **Files**: Use clear, descriptive names that indicate the content's purpose
   - Backend: `snake_case.py`
   - Frontend: `PascalCase.js` for components, `camelCase.js` for utilities

2. **Functions and Variables**:
   - Backend: Use `snake_case` for functions and variables
   - Frontend: Use `camelCase` for functions and variables

3. **Classes**:
   - Use `PascalCase` for all class names (both backend and frontend)

## Implementation Strategy

When a file approaches 250 lines:
1. Review the file for logical separation points
2. Identify functionality that can be extracted
3. Create new files with focused responsibilities
4. Update imports and references accordingly

## Documentation

Each file should include:
1. A brief header comment explaining its purpose
2. Documentation for public functions and classes
3. Comments for complex logic sections

## Server Startup and Environment Rules

1. **Mandatory Script Usage and Directory**:
   - Käivitamisskripti (start_servers.sh) **PEAB** kasutama rakenduse käivitamiseks
   - Skripti **PEAB** käivitama projekti juurkataloogist: `/home/gerri/Dokumendid/progemine/nature-photo-db/`
   - Õige käsk on: `cd /home/gerri/Dokumendid/progemine/nature-photo-db/ && ./start_servers.sh`
   - Käsitsi käivitatud serverid ei ole lubatud, et vältida ebajärjepidevaid keskkonnaseadistusi
   - Skript tagab järjestikuse käivitamise: andmebaas → backend → frontend

2. **Python Version Requirement**:
   - Projekti **PEAB** käivitama ainult Python3 käsuga (`python3`)
   - Käsk `python` ei toimi sellel süsteemil korrektselt
   - Kõigis skriptides ja dokumentatsioonis tuleb kasutada selgelt `python3` viiteid
   - Käsitsi serverite taaskäivitamisel tuleb alati kasutada käsku: `cd /home/gerri/Dokumendid/progemine/nature-photo-db/backend && python3 main.py`

3. **Database Schema Updates**:
   - Andmebaasi skeemi muudatused tuleb teha läbi `update_schema.py` skripti
   - Enne koodi muudatuste tegemist peavad andmebaasi tabelid olema värskendatud
   - Pärast andmebaasi muudatusi tuleb käivitada testid, et kontrollida ühilduvust

4. **Environment Preparation**:
   - Käivitusskript peab kontrollima ja looma:
     - Virtuaalkeskkonda
     - Vajalikke pakette (dependencies)
     - Andmebaasi ühendust
     - Failide salvestamise katalooge

5. **Error Handling and Logs**:
   - Kõik käivitusprotsessi vead peavad olema salvestatud logifailidesse
   - Kood peab kontrollima, kas vajalikud väliskeskkonna komponendid on saadaval

6. **Configuration Management**:
   - Keskkonna seaded peavad olema eraldatud `.env` failides
   - Käivitusskript peab tuvastama arendus- ja tootmiskeskkonna

## Monitoring and Enforcement

1. Configure your IDE to show line numbers
2. Set up a pre-commit hook or CI check to validate file lengths
3. Conduct regular code reviews focusing on file organization and length