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
    icon: "https://framerusercontent.com/images/hyQRAJJoXaCLvlAd8IqafkKPitE.svg",
  },
  chromadb: {
    name: "ChromaDB",
    description: "The AI-native embedding database",
    icon: "https://framerusercontent.com/images/chCSrOajsbttAYyRnFvhNbRgBEQ.svg",
  },
  clickhouse: {
    name: "ClickHouse",
    description: "Column-oriented database for real-time analytics at scale",
  },
  cockroachdb: {
    name: "CockroachDB",
    description: "Source-available distributed SQL database management system",
    icon: "https://framerusercontent.com/images/yYgMVdoJyroUzIpxfhPZkgzb0OA.svg",
  },
  dgraph: {
    name: "Dgraph",
    description: "The high-performance database for modern applications",
    icon: "https://framerusercontent.com/images/PqVSCt2usAAIShQahcf90ovxXqI.svg",
  },
  holmesgpt: {
    name: "HolmesGPT",
    description: "AI agent that investigates production incidents for you",
  },
  jupyterhub: {
    name: "Jupyterhub",
    description: "JupyterLab Is A Next-Generation Notebook Interface",
    icon: "https://framerusercontent.com/images/hgWz13blJI6voMJlnl8LpCs7Cjs.svg",
  },
  kafka: {
    name: "Kafka",
    description:
      "A distributed event streaming platform for real-time data pipelines and stream processing.",
    icon: "https://framerusercontent.com/images/T58vVQTZl0UnFlmzHJLYR7mpd8U.svg",
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
    icon: "https://framerusercontent.com/images/MrgrzzqL3aHPeAvXraV4W437EI.svg",
  },
  mysql: {
    name: "MySQL",
    description: "Deploy a MySQL database service",
    icon: "https://framerusercontent.com/images/o9NXlQW93tQQ6v3jTjDOcwxCMaU.svg",
  },
  opentsdb: {
    name: "OpenTSDB",
    description: "A Distributed, Scalable Monitoring System",
    icon: "https://framerusercontent.com/images/HMe9loL8PZLicwfLI1znIttA2g.png",
  },
  outline: {
    name: "Outline",
    description: "Beautiful, realtime collaborative, feature packed, and markdown compatible.",
    icon: "https://framerusercontent.com/images/me3PE9f0sDhtHyIisE955ABYK3c.svg",
  },
  postgres: {
    name: "Postgres",
    description: "PostgreSQL database service",
    icon: "https://framerusercontent.com/images/AaiB0a2xIUnIemm6V905ML5c.svg",
  },
  redis: {
    name: "Redis",
    description: "Redis key-value data store",
    icon: "https://framerusercontent.com/images/8MWCYgdUmGTAMwJBrF8PdkFbfnI.svg",
  },
  redisdistributed: {
    name: "Redis (Distributed)",
    description: "Distributed Redis cluster for high availability and scalability",
    icon: "https://framerusercontent.com/images/UijaNkqS0HW6UsMqM12w0Pg.png",
  },
  scylladb: {
    name: "ScyllaDB",
    description: "ScyllaDB is a source-available distributed NoSQL wide-column data store.",
    icon: "https://framerusercontent.com/images/0MeJnJIpldPqz476W6rAWBSO4XE.svg",
  },
  solr: {
    name: "SOLR",
    description: "An open-source search platform built on Apache Lucene.",
    icon: "https://framerusercontent.com/images/38xBPcJEGig795UQddhD41ra5xM.svg",
  },
  solrcloud: {
    name: "Solr Cloud",
    description: "Scalable, fault-tolerant Apache Solr for distributed search and indexing.",
    icon: "https://framerusercontent.com/images/TF8qLyaVZCZ0P3IwWEqp9qfNH1A.svg",
  },
  superset: {
    name: "Superset",
    description: "Data Visualization and Data Exploration | Looker, Tableau alternative",
    icon: "https://framerusercontent.com/images/j2PaA4EyjB3z8Te54CPtEl9G4pg.svg",
  },
  surrealdb: {
    name: "SurrealDB",
    description: "A scalable, distributed, collaborative, document-graph database",
    icon: "https://framerusercontent.com/images/bRyFhCW7zQ6XoCJv18CxnK8uE.svg",
  },
  wordpress: {
    name: "WordPress",
    description: "A content management system (CMS) written in PHP",
    icon: "https://framerusercontent.com/images/1tMwCNL8nyVYanLeO1YXCmyD8.svg",
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
