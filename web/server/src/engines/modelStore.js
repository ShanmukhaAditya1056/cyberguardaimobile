import fs from 'node:fs/promises';
import path from 'node:path';

import { MODELS_DIR } from '../config/env.js';

/**
 * Loads the JSON model exports once at boot and holds them in memory.
 *
 * These are the same files the Flutter app ships in `assets/models/` — around
 * 2.5 MB of decision trees and GCN weights. Parsing them per request would add
 * tens of milliseconds to every scan for no benefit, since they never change
 * while the process is alive.
 *
 * A missing or unreadable model is not fatal. The mobile app degrades to its
 * rules engine when an asset fails to load, and the API does the same, so a
 * deployment that forgot to copy `assets/` still answers every endpoint —
 * with rules-only verdicts and `mlAvailable: false` in the response so the
 * caller knows.
 */

const state = {
  phishing: null,
  malwareRf: null,
  malwareLgbm: null,
  malwareGnn: null,
  wifi: null,
  errors: [],
  loaded: false,
};

async function readModel(filename) {
  const full = path.join(MODELS_DIR, filename);
  const raw = await fs.readFile(full, 'utf8');
  return JSON.parse(raw);
}

async function tryLoad(key, filename, transform) {
  try {
    const json = await readModel(filename);
    state[key] = transform(json);
  } catch (err) {
    state[key] = null;
    state.errors.push(`${filename}: ${err.message}`);
  }
}

export async function loadModels() {
  if (state.loaded) return status();
  state.loaded = true;
  state.errors = [];

  await Promise.all([
    tryLoad('phishing', 'phishing_weights.json', (json) => {
      const model = json.model;
      if (!model) throw new Error('missing `model` block');
      if (model.kind !== 'logistic_regression' && model.kind !== 'random_forest') {
        throw new Error(`unknown model kind: ${model.kind}`);
      }
      return {
        kind: model.kind,
        weights: model.weights,
        bias: model.bias,
        trees: model.trees,
        metadata: {
          modelType: json.model_type,
          trainedAt: json.trained_at,
          trainingSamples: json.training_samples,
          testMetrics: json.test_metrics,
        },
      };
    }),

    tryLoad('malwareRf', 'malware_rf_weights.json', (json) => ({
      trees: json.model.trees,
      metadata: { trainedAt: json.trained_at, testMetrics: json.test_metrics },
    })),

    tryLoad('malwareLgbm', 'malware_lgbm_weights.json', (json) => ({
      trees: json.model.trees,
      metadata: { trainedAt: json.trained_at, testMetrics: json.test_metrics },
    })),

    tryLoad('malwareGnn', 'malware_gnn_weights.json', (json) => ({
      layers: json.layers,
      savedTestAccuracy: json.saved_test_accuracy,
    })),

    tryLoad('wifi', 'wifi_isoforest_weights.json', (json) => ({
      trees: json.model.trees,
      scalerMean: json.scaler.mean,
      scalerScale: json.scaler.scale,
      offset: json.offset,
      maxSamples: json.max_samples,
      metadata: {
        nEstimators: json.n_estimators,
        trainedAt: json.trained_at,
      },
    })),
  ]);

  return status();
}

export function models() {
  return state;
}

/** Which engines came up, for `/api/health` and the client's status banner. */
export function status() {
  return {
    phishing: state.phishing !== null,
    malwareRf: state.malwareRf !== null,
    malwareLgbm: state.malwareLgbm !== null,
    malwareGnn: state.malwareGnn !== null,
    wifi: state.wifi !== null,
    modelsDir: MODELS_DIR,
    errors: state.errors,
  };
}
