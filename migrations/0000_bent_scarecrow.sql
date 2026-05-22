CREATE TABLE "user_devices" (
	"id" varchar PRIMARY KEY NOT NULL,
	"user_id" varchar NOT NULL,
	"device_id" varchar NOT NULL,
	"device_name" varchar NOT NULL,
	"device_type" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "user_invites" (
	"id" varchar PRIMARY KEY NOT NULL,
	"email" varchar NOT NULL,
	"team_id" varchar NOT NULL,
	"role_id" varchar NOT NULL,
	"status" varchar NOT NULL,
	"expired_at" timestamp with time zone NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "user_plivo_credential" (
	"user_id" varchar PRIMARY KEY NOT NULL,
	"id" varchar NOT NULL,
	"username" varchar NOT NULL,
	"password" varchar NOT NULL,
	"alias" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" varchar PRIMARY KEY NOT NULL,
	"firebase_id" varchar NOT NULL,
	"email" varchar NOT NULL,
	"phone_number" varchar,
	"first_name" varchar,
	"last_name" varchar,
	"last_login_at" timestamp with time zone,
	"last_login_method" varchar,
	"internal_role" varchar,
	"stripe_customer_id" varchar,
	"alias_token" varchar,
	"onboarding_tasks" boolean[],
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "organizations" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"owner_id" varchar,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "users_organizations" (
	"users_id" varchar NOT NULL,
	"organizations_id" varchar NOT NULL,
	CONSTRAINT "users_organizations_users_id_organizations_id_pk" PRIMARY KEY("users_id","organizations_id")
);
--> statement-breakpoint
CREATE TABLE "teams" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"organization_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "users_teams_roles" (
	"user_id" varchar NOT NULL,
	"team_id" varchar NOT NULL,
	"role_id" varchar NOT NULL,
	CONSTRAINT "users_teams_roles_user_id_team_id_role_id_pk" PRIMARY KEY("user_id","team_id","role_id")
);
--> statement-breakpoint
CREATE TABLE "permissions" (
	"id" varchar PRIMARY KEY NOT NULL,
	"scope" text NOT NULL,
	"action" text NOT NULL,
	"type" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "roles" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"organization_id" varchar NOT NULL,
	"default" boolean NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "roles_permissions" (
	"roles_id" varchar NOT NULL,
	"permissions_id" varchar NOT NULL,
	CONSTRAINT "roles_permissions_roles_id_permissions_id_pk" PRIMARY KEY("roles_id","permissions_id")
);
--> statement-breakpoint
CREATE TABLE "checks" (
	"id" varchar PRIMARY KEY NOT NULL,
	"type" varchar NOT NULL,
	"title" varchar,
	"tags" text[],
	"url" varchar NOT NULL,
	"port" integer,
	"locations" text[],
	"interval" integer NOT NULL,
	"status" varchar NOT NULL,
	"recover_period" integer NOT NULL,
	"confirm_period" integer,
	"handle_redirect" boolean DEFAULT true,
	"method" varchar NOT NULL,
	"request_headers" jsonb,
	"request_body" text,
	"required_keyword" text,
	"timeout" integer,
	"expected_status_codes" integer[],
	"last_checked_at" timestamp,
	"paused_at" timestamp,
	"maintenance_days" varchar[],
	"maintenance_from" varchar,
	"maintenance_to" varchar,
	"maintenance_time_zone" varchar,
	"auth_username" varchar,
	"auth_password" varchar,
	"escalation_id" varchar,
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "regions" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "workers" (
	"id" varchar PRIMARY KEY NOT NULL,
	"ip" varchar NOT NULL,
	"type" varchar NOT NULL,
	"location" varchar NOT NULL,
	"region" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "custom_incidents" (
	"id" varchar PRIMARY KEY NOT NULL,
	"title" varchar,
	"status" varchar NOT NULL,
	"escalation_id" varchar,
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "escalation_contacts" (
	"id" varchar PRIMARY KEY NOT NULL,
	"contact_type" varchar NOT NULL,
	"contact_id" varchar,
	"escalation_step_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "escalation_steps" (
	"id" varchar PRIMARY KEY NOT NULL,
	"step_delay" integer NOT NULL,
	"severity_id" varchar NOT NULL,
	"escalation_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "escalations" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"repeat_count" integer DEFAULT 0 NOT NULL,
	"repeat_delay" integer DEFAULT 0 NOT NULL,
	"resolution_alerts" text,
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "severities" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar DEFAULT 'Critical alert' NOT NULL,
	"alerts" varchar[],
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "on_call_schedulers" (
	"id" varchar PRIMARY KEY NOT NULL,
	"type" varchar NOT NULL,
	"start_date" timestamp with time zone NOT NULL,
	"end_date" timestamp with time zone,
	"all_day" boolean,
	"recurring_pattern" varchar,
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "on_call_schedulers_users" (
	"on_call_schedulers_id" varchar NOT NULL,
	"users_id" varchar NOT NULL,
	CONSTRAINT "on_call_schedulers_users_on_call_schedulers_id_users_id_pk" PRIMARY KEY("on_call_schedulers_id","users_id")
);
--> statement-breakpoint
CREATE TABLE "plan_resource_limits" (
	"id" varchar PRIMARY KEY NOT NULL,
	"subscription_plan_id" varchar NOT NULL,
	"resource_type" varchar NOT NULL,
	"included_quantity" integer DEFAULT 0 NOT NULL,
	"overage_price" integer NOT NULL,
	"overage_stripe_price_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "promotion_codes" (
	"id" varchar PRIMARY KEY NOT NULL,
	"code" varchar NOT NULL,
	"stripe_promotion_code_id" varchar NOT NULL,
	"stripe_coupon_id" varchar NOT NULL,
	"name" varchar,
	"description" text,
	"discount_type" varchar DEFAULT 'percent' NOT NULL,
	"discount_value" integer NOT NULL,
	"currency" varchar,
	"duration" varchar DEFAULT 'once' NOT NULL,
	"duration_in_months" integer,
	"max_redemptions" integer,
	"times_redeemed" integer DEFAULT 0 NOT NULL,
	"expires_at" timestamp with time zone,
	"min_order_amount" integer,
	"applicable_plan_ids" jsonb,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar,
	CONSTRAINT "promotion_codes_code_unique" UNIQUE("code"),
	CONSTRAINT "promotion_codes_stripe_promotion_code_id_unique" UNIQUE("stripe_promotion_code_id")
);
--> statement-breakpoint
CREATE TABLE "subscription_items" (
	"id" varchar PRIMARY KEY NOT NULL,
	"subscription_id" varchar NOT NULL,
	"stripe_subscription_item_id" varchar,
	"stripe_price_id" varchar NOT NULL,
	"subscription_plan_id" varchar NOT NULL,
	"item_type" varchar NOT NULL,
	"quantity" integer DEFAULT 1 NOT NULL,
	"status" varchar NOT NULL,
	"start_date" date,
	"end_date" date,
	"resource_type" varchar,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar,
	CONSTRAINT "subscription_items_stripe_subscription_item_id_unique" UNIQUE("stripe_subscription_item_id")
);
--> statement-breakpoint
CREATE TABLE "subscription_plans" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"plan_type" varchar NOT NULL,
	"source" varchar NOT NULL,
	"period" varchar NOT NULL,
	"stripe_price_id" varchar,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "subscription_usage" (
	"id" varchar PRIMARY KEY NOT NULL,
	"organization_id" varchar NOT NULL,
	"subscription_item_id" varchar,
	"usage_type" varchar NOT NULL,
	"usage_value" integer NOT NULL,
	"usage_timestamp" timestamp NOT NULL,
	"billing_cycle_start_date" date,
	"billing_cycle_end_date" date,
	"reported_to_stripe" boolean,
	"stripe_price_id" varchar,
	"stripe_usage_record_id" varchar,
	"is_billable" boolean,
	"notes" varchar,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "subscriptions" (
	"id" varchar PRIMARY KEY NOT NULL,
	"organization_id" varchar NOT NULL,
	"stripe_customer_id" varchar,
	"stripe_subscription_id" varchar,
	"status" varchar NOT NULL,
	"current_period_start_date" date,
	"current_period_end_date" date,
	"canceled_at" timestamp,
	"grace_period_ends_at" timestamp,
	"usage_billing_enabled" boolean DEFAULT true,
	"overage_policy_fixed_resources" varchar DEFAULT 'CHARGE',
	"source" varchar NOT NULL,
	"cancel_at_period_end" boolean DEFAULT false,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar,
	CONSTRAINT "subscriptions_stripe_subscription_id_unique" UNIQUE("stripe_subscription_id")
);
--> statement-breakpoint
CREATE TABLE "status_pages" (
	"id" varchar PRIMARY KEY NOT NULL,
	"team_id" varchar,
	"company_name" varchar,
	"sub_domain" varchar NOT NULL,
	"get_in_touch_url" varchar,
	"customdomain" varchar,
	"announcement" varchar,
	"min_incident_length" integer,
	"timezone" varchar,
	"status_page_day" integer,
	"auto_update" boolean DEFAULT false,
	"publish_status_page" boolean DEFAULT false,
	"status_sections" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "status_reports" (
	"id" varchar PRIMARY KEY NOT NULL,
	"status_page_id" varchar,
	"summary" varchar,
	"report_type" varchar NOT NULL,
	"status" varchar,
	"from" timestamp with time zone,
	"to" timestamp with time zone,
	"affected_resources" jsonb,
	"report_updates" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "integration-settings" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"type" varchar NOT NULL,
	"identity" varchar,
	"config" jsonb,
	"team_id" varchar NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp,
	"created_by" varchar,
	"updated_by" varchar
);
--> statement-breakpoint
CREATE TABLE "tokens" (
	"id" varchar PRIMARY KEY NOT NULL,
	"name" varchar NOT NULL,
	"level" varchar,
	"owner_id" varchar,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp
);
--> statement-breakpoint
ALTER TABLE "escalation_steps" ADD CONSTRAINT "escalation_steps_escalation_id_escalations_id_fk" FOREIGN KEY ("escalation_id") REFERENCES "public"."escalations"("id") ON DELETE no action ON UPDATE no action;