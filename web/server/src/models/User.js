import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';

/**
 * An account.
 *
 * The mobile app keeps everything in an encrypted Hive box on the device and
 * needs no server-side identity at all. The web build cannot: a browser has no
 * durable, private local store worth trusting with scan history, so history
 * lives here — and that makes the account boundary the only thing separating
 * one user's findings from another's. Every history model below is scoped by
 * `user` and every query filters on it.
 */
const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Enter a valid email address'],
    },
    /**
     * Set when this account signs in through Firebase — the same identity the
     * phone uses, which is what makes one login work on both.
     *
     * `sparse` matters: without it, every local account would share a `null`
     * value and the unique index would reject all but the first one.
     */
    firebaseUid: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
      default: undefined,
    },

    /**
     * `select: false` keeps the hash out of every query that does not ask for
     * it by name, so a careless `res.json(user)` cannot leak it.
     *
     * Not required: a Firebase-backed account has no password here, because
     * Firebase holds it. Requiring one would mean inventing a random hash
     * nobody can use, and a dead credential in the database is worse than an
     * absent one — it looks like a usable login path in any later audit.
     */
    passwordHash: { type: String, select: false },
    displayName: { type: String, trim: true, maxlength: 80, default: '' },

    settings: {
      realTimeAlerts: { type: Boolean, default: true },
      saveScanHistory: { type: Boolean, default: true },
      locale: { type: String, default: 'en', enum: ['en', 'hi', 'ta', 'te'] },
    },

    lastLoginAt: { type: Date },
  },
  { timestamps: true },
);

/**
 * Cost 12 is the current sensible floor: roughly 250 ms per hash on commodity
 * hardware, slow enough to make offline cracking expensive and fast enough
 * that a login does not feel stalled.
 */
userSchema.methods.setPassword = async function setPassword(plain) {
  this.passwordHash = await bcrypt.hash(plain, 12);
};

userSchema.methods.verifyPassword = function verifyPassword(plain) {
  // A Firebase-backed account has no local hash. bcrypt.compare against
  // undefined resolves false in some versions and throws in others, so the
  // answer is given explicitly: there is no local password to match.
  if (!this.passwordHash) return Promise.resolve(false);
  return bcrypt.compare(plain, this.passwordHash);
};

userSchema.methods.toPublic = function toPublic() {
  return {
    id: this._id.toString(),
    email: this.email,
    displayName: this.displayName,
    settings: this.settings,
    createdAt: this.createdAt,
    // Which credential signs this account in. The settings screen uses it to
    // show "managed by your Google account" instead of a change-password form
    // that could not work. The uid itself is not exposed — it is an internal
    // join key, and the client has no use for it.
    authProvider: this.firebaseUid ? 'firebase' : 'local',
  };
};

export const User = mongoose.model('User', userSchema);
