# Component Library Restriction Protocol

**Purpose:** Prevent UI code bloat by enforcing use of the established component library (shadcn/ui). AI tends to reinvent components - this protocol stops that.

## The Problem

AI loves creating new components from scratch:

```tsx
// AI writes this 50 times in different files:
const Button = ({ children, onClick, variant }) => (
  <button
    className={`px-4 py-2 rounded ${variant === 'primary' ? 'bg-blue-500' : 'bg-gray-200'}`}
    onClick={onClick}
  >
    {children}
  </button>
);
```

This leads to:
- 15 different Button implementations
- Inconsistent styling
- Duplicated code
- Maintenance nightmare

## The Rule

> **You are FORBIDDEN from creating new CSS classes or styled components for common UI patterns. You MUST use shadcn/ui components.**

## Enforced Component Usage

### Required Components (Use These, Don't Reinvent)

| UI Pattern | shadcn/ui Component | Import |
|------------|---------------------|--------|
| Buttons | `Button` | `@/components/ui/button` |
| Text inputs | `Input` | `@/components/ui/input` |
| Dropdowns | `Select` | `@/components/ui/select` |
| Modals | `Dialog` | `@/components/ui/dialog` |
| Popovers | `Popover` | `@/components/ui/popover` |
| Cards | `Card` | `@/components/ui/card` |
| Forms | `Form` | `@/components/ui/form` |
| Tables | `Table` | `@/components/ui/table` |
| Tabs | `Tabs` | `@/components/ui/tabs` |
| Badges | `Badge` | `@/components/ui/badge` |
| Alerts | `Alert` | `@/components/ui/alert` |
| Progress | `Progress` | `@/components/ui/progress` |
| Tooltips | `Tooltip` | `@/components/ui/tooltip` |
| Checkboxes | `Checkbox` | `@/components/ui/checkbox` |
| Radio buttons | `RadioGroup` | `@/components/ui/radio-group` |
| Toggles | `Switch` | `@/components/ui/switch` |
| Sliders | `Slider` | `@/components/ui/slider` |
| Loading | `Skeleton` | `@/components/ui/skeleton` |
| Navigation | `NavigationMenu` | `@/components/ui/navigation-menu` |
| Breadcrumbs | `Breadcrumb` | `@/components/ui/breadcrumb` |

### Forbidden Patterns

**1. Custom button implementations:**
```tsx
// ❌ FORBIDDEN
const CustomButton = styled.button`...`;
const MyButton = ({ ...props }) => <button className="...">...</button>;

// ✅ REQUIRED
import { Button } from "@/components/ui/button";
<Button variant="default" size="sm">Click me</Button>
```

**2. Custom input styling:**
```tsx
// ❌ FORBIDDEN
<input className="border rounded px-2 py-1" />

// ✅ REQUIRED
import { Input } from "@/components/ui/input";
<Input placeholder="Enter value" />
```

**3. Custom modal implementations:**
```tsx
// ❌ FORBIDDEN
const Modal = ({ isOpen, onClose, children }) => (
  isOpen && <div className="fixed inset-0 bg-black/50">...</div>
);

// ✅ REQUIRED
import { Dialog, DialogContent, DialogHeader } from "@/components/ui/dialog";
<Dialog open={isOpen} onOpenChange={setIsOpen}>
  <DialogContent>...</DialogContent>
</Dialog>
```

**4. Custom card styling:**
```tsx
// ❌ FORBIDDEN
<div className="border rounded-lg shadow p-4">

// ✅ REQUIRED
import { Card, CardContent, CardHeader } from "@/components/ui/card";
<Card>
  <CardHeader>Title</CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

## Exception Process

If you genuinely need a custom component that shadcn/ui doesn't provide:

### Step 1: Search First

```bash
# Check if component exists
ls frontend/src/components/ui/
# Check shadcn/ui docs
# Check if similar component can be extended
```

### Step 2: Document Why

```tsx
/**
 * Custom component: AudioWaveform
 *
 * Justification: No shadcn/ui equivalent exists.
 * Audio visualization requires custom canvas rendering.
 *
 * Checked alternatives:
 * - Progress: Doesn't support waveform visualization
 * - Custom SVG: Too complex for real-time updates
 */
```

### Step 3: Follow Project Patterns

New custom components must:
- Live in `components/ui/` or `components/custom/`
- Use the same styling conventions (Tailwind, CSS variables)
- Export properly from index file
- Have a Storybook story (if applicable)
- Be documented in component library

## Detection Script

This script runs on PreToolUse for `.tsx` file writes:

```bash
#!/bin/bash
# .claude/scripts/check-component-usage.sh

FILE="$1"

# Patterns that suggest custom component creation
VIOLATIONS=()

# Check for custom button implementations
if grep -qE "const.*Button.*=.*\(|styled\.button" "$FILE"; then
    if ! grep -q "from.*@/components/ui/button" "$FILE"; then
        VIOLATIONS+=("Custom Button implementation without using shadcn/ui Button")
    fi
fi

# Check for inline styling that should use components
if grep -qE 'className="[^"]*border.*rounded.*shadow' "$FILE"; then
    if ! grep -q "from.*@/components/ui/card" "$FILE"; then
        VIOLATIONS+=("Card-like styling without using Card component")
    fi
fi

# Check for modal patterns
if grep -qE "fixed.*inset-0|className.*modal" "$FILE"; then
    if ! grep -q "from.*@/components/ui/dialog" "$FILE"; then
        VIOLATIONS+=("Modal pattern without using Dialog component")
    fi
fi

if [ ${#VIOLATIONS[@]} -gt 0 ]; then
    echo "⚠️ COMPONENT LIBRARY VIOLATION"
    echo ""
    echo "File: $FILE"
    echo ""
    echo "Issues:"
    for v in "${VIOLATIONS[@]}"; do
        echo "  - $v"
    done
    echo ""
    echo "Use shadcn/ui components instead of creating custom ones."
    echo "See: .claude/protocols/component-library-restriction.md"
fi
```

## Integration

This protocol is enforced via:

1. **PreToolUse hook** for Write operations on `.tsx` files
2. **shadow-code-reviewer** includes component usage check
3. **Gardener agent** identifies duplicate component patterns
4. **PR review checklist** includes component library compliance

## Benefits

- **Consistency:** All buttons look the same
- **Maintainability:** One place to update styles
- **Accessibility:** shadcn/ui has built-in a11y
- **Performance:** Shared components = smaller bundle
- **Developer Experience:** Don't reinvent the wheel
