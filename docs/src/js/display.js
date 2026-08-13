// Presentation only. Which charts appear on the site, and under which
// category, is decided entirely by docs/index.yaml — nothing here gates a chart.
//
// A new chart needs no edit to this file: it inherits a title-cased name, the
// description and icon from its Chart.yaml, and a title-cased category label.
// The tables below only exist so brand names read correctly ("ClickHouse", not
// "Clickhouse") and so the copy already written for the launched integrations
// survives the move to index.yaml.

// annotations.type -> the category heading shown on the site.
const TYPE_LABELS = {
  application: "Applications",
  datasource: "Datastore",
}

// Categories are listed in this order; any type not named here follows, sorted
// alphabetically by label.
const TYPE_ORDER = ["application", "datasource"]

// Optional per-chart copy. Any field left out falls back to index.yaml.
const CHART_DISPLAY = {
  cassandra: {
    name: "Cassandra",
    description:
      "Storing and managing large volumes of structured, semi-structured, and unstructured data.",
  },
  chromadb: {
    name: "ChromaDB",
    description: "The AI-native embedding database",
  },
  clickhouse: {
    name: "ClickHouse",
    description: "Column-oriented database for real-time analytics at scale",
  },
  cockroachdb: {
    name: "CockroachDB",
    description: "Source-available distributed SQL database management system",
  },
  dgraph: {
    name: "Dgraph",
    description: "The high-performance database for modern applications",
  },
  holmesgpt: {
    name: "HolmesGPT",
    description: "AI agent that investigates production incidents for you",
  },
  jupyterhub: {
    name: "Jupyterhub",
    description: "JupyterLab Is A Next-Generation Notebook Interface",
  },
  kafka: {
    name: "Kafka",
    description:
      "A distributed event streaming platform for real-time data pipelines and stream processing.",
  },
  litellm: {
    name: "LiteLLM",
    description: "One OpenAI-compatible proxy in front of every LLM provider",
  },
  localai: {
    name: "LocalAI",
    description: "OpenAI-compatible inference API that runs models on your own cluster",
  },
  mariadb: {
    name: "MariaDB",
    description: "The open source relational database",
  },
  mysql: {
    name: "MySQL",
    description: "Deploy a MySQL database service",
  },
  opentsdb: {
    name: "OpenTSDB",
    description: "A Distributed, Scalable Monitoring System",
  },
  outline: {
    name: "Outline",
    description: "Beautiful, realtime collaborative, feature packed, and markdown compatible.",
  },
  postgres: {
    name: "Postgres",
    description: "PostgreSQL database service",
  },
  redis: {
    name: "Redis",
    description: "Redis key-value data store",
  },
  redisdistributed: {
    name: "Redis (Distributed)",
    description: "Distributed Redis cluster for high availability and scalability",
  },
  scylladb: {
    name: "ScyllaDB",
    description: "ScyllaDB is a source-available distributed NoSQL wide-column data store.",
  },
  solr: {
    name: "SOLR",
    description: "An open-source search platform built on Apache Lucene.",
  },
  solrcloud: {
    name: "Solr Cloud",
    description: "Scalable, fault-tolerant Apache Solr for distributed search and indexing.",
  },
  superset: {
    name: "Superset",
    description: "Data Visualization and Data Exploration | Looker, Tableau alternative",
  },
  surrealdb: {
    name: "SurrealDB",
    description: "A scalable, distributed, collaborative, document-graph database",
  },
  wordpress: {
    name: "WordPress",
    description: "A content management system (CMS) written in PHP",
  },
}

const FALLBACK_ICON = "./src/assets/logo.png"

export function titleCase(value) {
  return String(value)
    .split(/[\s_-]+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ")
}

export function labelForType(type) {
  return TYPE_LABELS[type] || titleCase(type)
}

export function sectionIdForLabel(label) {
  return `${label.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")}-section`
}

// Merges an index.yaml entry with its optional display copy.
export function toCard(integration) {
  const override = CHART_DISPLAY[integration.id] || {}
  const label = labelForType(integration.type)

  return {
    ...integration,
    name: override.name || titleCase(integration.id),
    description: override.description || integration.description,
    icon: override.icon || integration.icon || FALLBACK_ICON,
    category: label,
    sectionId: sectionIdForLabel(label),
  }
}

// Groups cards into the categories the sidebar and sections are built from.
export function groupByCategory(integrations) {
  const groups = new Map()

  integrations.map(toCard).forEach((card) => {
    if (!groups.has(card.type)) {
      groups.set(card.type, {
        type: card.type,
        label: card.category,
        sectionId: card.sectionId,
        items: [],
      })
    }

    groups.get(card.type).items.push(card)
  })

  const rank = (type) => {
    const index = TYPE_ORDER.indexOf(type)
    return index === -1 ? TYPE_ORDER.length : index
  }

  return [...groups.values()]
    .map((group) => ({
      ...group,
      items: group.items.sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => rank(a.type) - rank(b.type) || a.label.localeCompare(b.label))
}
