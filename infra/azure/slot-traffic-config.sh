#!/bin/bash

################################################################################
# Azure App Service Slot Traffic Configuration Script
#
# This script helps you manage traffic routing between deployment slots.
# Use cases:
# 1. Blue-Green Deployment: Swap slots instantly (0% or 100%)
# 2. Canary Deployment: Route percentage of traffic to new version
# 3. A/B Testing: Split traffic between versions
#
# Prerequisites:
# - Azure CLI installed and logged in
# - App Service with deployment slots created
#
# Usage:
#   ./slot-traffic-config.sh <app-name> <resource-group> <action> [parameters]
#
# Actions:
#   swap <source-slot> <target-slot>     - Swap two slots (blue-green)
#   route <slot-name> <percentage>       - Route traffic percentage to slot (canary)
#   reset                                - Reset all traffic to production
#   status                               - Show current traffic routing
#
# Examples:
#   # Blue-Green: Swap staging to production
#   ./slot-traffic-config.sh myapp mygroup swap staging production
#
#   # Canary: Route 10% traffic to staging
#   ./slot-traffic-config.sh myapp mygroup route staging 10
#
#   # Reset: All traffic back to production
#   ./slot-traffic-config.sh myapp mygroup reset
#
#   # Status: Show current routing
#   ./slot-traffic-config.sh myapp mygroup status
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
APP_NAME="$1"
RESOURCE_GROUP="$2"
ACTION="$3"

# Validate required arguments
if [ -z "$APP_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$ACTION" ]; then
    print_error "Missing required arguments!"
    echo ""
    echo "Usage: $0 <app-name> <resource-group> <action> [parameters]"
    echo ""
    echo "Actions:"
    echo "  swap <source-slot> <target-slot>  - Swap two slots"
    echo "  route <slot-name> <percentage>    - Route traffic percentage"
    echo "  reset                             - Reset to production only"
    echo "  status                            - Show current routing"
    echo ""
    exit 1
fi

print_info "Traffic Configuration Tool"
echo ""
print_info "App Name: $APP_NAME"
print_info "Resource Group: $RESOURCE_GROUP"
print_info "Action: $ACTION"
echo ""

################################################################################
# Check Prerequisites
################################################################################
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed."
    exit 1
fi

if ! az account show &> /dev/null; then
    print_error "Not logged in to Azure. Run 'az login' first."
    exit 1
fi

# Verify app exists
if ! az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_error "App '$APP_NAME' not found in resource group '$RESOURCE_GROUP'"
    exit 1
fi

################################################################################
# Action: Show Status
################################################################################
show_status() {
    print_info "Current Traffic Routing Configuration:"
    echo ""

    # Get traffic routing rules
    ROUTING=$(az webapp traffic-routing show \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query '[].{Slot:name, Traffic:trafficPercentage}' \
        --output table)

    if [ -z "$ROUTING" ]; then
        print_info "No traffic routing rules configured."
        print_info "100% of traffic goes to production slot."
    else
        echo "$ROUTING"
    fi

    echo ""
    print_info "Available Slots:"
    az webapp deployment slot list \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query '[].name' \
        --output table
}

################################################################################
# Action: Swap Slots (Blue-Green Deployment)
################################################################################
swap_slots() {
    SOURCE_SLOT="$1"
    TARGET_SLOT="$2"

    if [ -z "$SOURCE_SLOT" ] || [ -z "$TARGET_SLOT" ]; then
        print_error "Both source and target slots are required for swap!"
        echo "Usage: $0 $APP_NAME $RESOURCE_GROUP swap <source-slot> <target-slot>"
        exit 1
    fi

    print_info "Swapping slots: $SOURCE_SLOT -> $TARGET_SLOT"
    print_warning "This will instantly route all traffic to the new version."
    echo ""

    # Perform the swap
    if [ "$TARGET_SLOT" == "production" ]; then
        # Swapping to production (no --target-slot parameter)
        print_info "Swapping '$SOURCE_SLOT' slot to production..."
        az webapp deployment slot swap \
            --name "$APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --slot "$SOURCE_SLOT"
    else
        # Swapping between two slots
        print_info "Swapping '$SOURCE_SLOT' with '$TARGET_SLOT'..."
        az webapp deployment slot swap \
            --name "$APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --slot "$SOURCE_SLOT" \
            --target-slot "$TARGET_SLOT"
    fi

    print_success "Slot swap completed!"
    echo ""
    print_info "Verifying deployment..."

    # Wait a moment for the swap to complete
    sleep 5

    # Show new status
    show_status
}

################################################################################
# Action: Route Traffic (Canary Deployment)
################################################################################
route_traffic() {
    SLOT_NAME="$1"
    PERCENTAGE="$2"

    if [ -z "$SLOT_NAME" ] || [ -z "$PERCENTAGE" ]; then
        print_error "Both slot name and percentage are required!"
        echo "Usage: $0 $APP_NAME $RESOURCE_GROUP route <slot-name> <percentage>"
        exit 1
    fi

    # Validate percentage
    if ! [[ "$PERCENTAGE" =~ ^[0-9]+$ ]] || [ "$PERCENTAGE" -lt 0 ] || [ "$PERCENTAGE" -gt 100 ]; then
        print_error "Percentage must be a number between 0 and 100"
        exit 1
    fi

    print_info "Routing $PERCENTAGE% of traffic to '$SLOT_NAME' slot"
    print_info "Remaining $((100 - PERCENTAGE))% will go to production"
    echo ""

    # Set traffic routing
    az webapp traffic-routing set \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --distribution "$SLOT_NAME=$PERCENTAGE"

    print_success "Traffic routing configured!"
    echo ""
    print_warning "Note: It may take a few minutes for routing changes to take effect."
    echo ""

    # Show new status
    show_status
}

################################################################################
# Action: Reset Traffic
################################################################################
reset_traffic() {
    print_info "Resetting traffic routing..."
    print_info "All traffic will be routed to production slot."
    echo ""

    # Clear all traffic routing rules
    az webapp traffic-routing clear \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP"

    print_success "Traffic routing reset!"
    echo ""

    # Show new status
    show_status
}

################################################################################
# Main Logic
################################################################################

case "$ACTION" in
    status)
        show_status
        ;;

    swap)
        SOURCE_SLOT="$4"
        TARGET_SLOT="$5"
        swap_slots "$SOURCE_SLOT" "$TARGET_SLOT"
        ;;

    route)
        SLOT_NAME="$4"
        PERCENTAGE="$5"
        route_traffic "$SLOT_NAME" "$PERCENTAGE"
        ;;

    reset)
        reset_traffic
        ;;

    *)
        print_error "Unknown action: $ACTION"
        echo ""
        echo "Valid actions: status, swap, route, reset"
        exit 1
        ;;
esac

echo ""
print_success "Done! 🎉"
