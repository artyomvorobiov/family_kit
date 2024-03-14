/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Firestore } = require('@google-cloud/firestore');
const { Filter } = require('@google-cloud/firestore');
const { Duration, DateTime } = require('luxon');
admin.initializeApp();

exports.notifyLowQuantity = functions.firestore.document('drugs/{drugId}')
    .onUpdate((change, context) => {
        const newValue = change.after.data();
        const oldValue = change.before.data();
        if (parseInt(newValue.quantity) < parseInt(newValue.quantityNum) && parseInt(oldValue.quantity) >= parseInt(oldValue.quantityNum)) {
            const familyId = newValue.familyId;

            // Получаем список пользователей с соответствующим familyId
            return admin.firestore().collection('users').where(
                Filter.or(
                    Filter.where('familyId', '==', familyId),
                    Filter.where('familyId2', '==', familyId),
                    Filter.where('familyId3', '==', familyId),
                  )
                  ).get()
                .then(querySnapshot => {
                    const promises = [];

                    // Отправляем уведомление каждому пользователю
                    querySnapshot.forEach(doc => {
                        const user = doc.data();
                        const token = user.tokenId;

                       
                        const notificationPayload = {
                            notification: {
                                title: 'Лекарство скоро закончится',
                                body: `У Вас заканчивается ${newValue.name}. Осталось ${newValue.quantity} ${newValue.storageOptions}.`,
                            },
                        };

                        promises.push(admin.messaging().sendToDevice(token, notificationPayload));
                    });

                    return Promise.all(promises);
                });
        }

        return null;
    });
    exports.notifyExpiringDrugs = functions.pubsub.schedule('every day 12:00').timeZone('Europe/Moscow').onRun(async (context) => {
        try {
            const currentDate = DateTime.now();
            const drugsSnapshot = await admin.firestore().collection('drugs').get();
            const promises = [];
    
            drugsSnapshot.forEach(async (drugDoc) => {
                const drugData = drugDoc.data();
                const parsedExpiryDate = DateTime.fromISO(drugData.expiryDate);
                
          
                if (currentDate.plus({ days: parseInt(drugData.notificationDays) }) >= parsedExpiryDate) {
                    const familyId = drugData.familyId;
    

                    const usersSnapshot = await admin.firestore().collection('users').where(
                    Filter.or(
                        Filter.where('familyId', '==', familyId),
                        Filter.where('familyId2', '==', familyId),
                        Filter.where('familyId3', '==', familyId),
                      )).get()
                    usersSnapshot.forEach((userDoc) => {
                        const user = userDoc.data();
                        const token = user.tokenId;
    
            
                        const notificationPayload = {
                            notification: {
                                title: 'Заканчивается срок годности',
                                body: `Срок годности лекарства ${drugData.name} заканчивается ${drugData.expiryDate}.`,
                            },
                        };
    
                        promises.push(admin.messaging().sendToDevice(token, notificationPayload));
                    });
                }
            });
    
            await Promise.all(promises);
            return null;
        } catch (error) {
            console.error('Error in notifyExpiringDrugs function:', error);
            throw new functions.https.HttpsError('internal', 'An error occurred while processing the function.');
        }
    });

    exports.notifyExpiredDrugs = functions.pubsub.schedule('every day 12:30').timeZone('Europe/Moscow').onRun(async (context) => {
        try {
            const currentDate = DateTime.now();
            const drugsSnapshot = await admin.firestore().collection('drugs').get();
            const promises = [];
    
            drugsSnapshot.forEach(async (drugDoc) => {
                const drugData = drugDoc.data();
                const parsedExpiryDate = DateTime.fromISO(drugData.expiryDate);
                
          
                if (currentDate > parsedExpiryDate) {
                    const familyId = drugData.familyId;
                    const usersSnapshot = await admin.firestore().collection('users').where(
                    Filter.or(
                        Filter.where('familyId', '==', familyId),
                        Filter.where('familyId2', '==', familyId),
                        Filter.where('familyId3', '==', familyId),
                      )).get()
                    usersSnapshot.forEach((userDoc) => {
                        const user = userDoc.data();
                        const token = user.tokenId;
    
            
                        const notificationPayload = {
                            notification: {
                                title: 'Заканчивается срок годности',
                                body: `Срок годностии лекарства ${drugData.name} закончился ${drugData.expiryDate}.`,
                            },
                        };
    
                        promises.push(admin.messaging().sendToDevice(token, notificationPayload));
                    });
                }
            });
    
            await Promise.all(promises);
            return null;
        } catch (error) {
            console.error('Error in notifyExpiringDrugs function:', error);
            throw new functions.https.HttpsError('internal', 'An error occurred while processing the function.');
        }
    });

    exports.notifyNewFamilyMember = functions.firestore.document('users/{userId}')
    .onUpdate((change, context) => {
        const newUser = change.after.data();

        const oldUser = change.before.data();

        const newFamilyId = newUser.familyId;
        const oldFamilyId = oldUser.familyId;

        const newFamilyId2 = newUser.familyId2;
        const oldFamilyId2 = oldUser.familyId2;

        const newFamilyId3 = newUser.familyId3;
        const oldFamilyId3 = oldUser.familyId3;

        const promises = [];

        if (newFamilyId && newFamilyId !== oldFamilyId) {
            promises.push(notifyFamilyMember(newFamilyId, newUser, context));
        }

        if (newFamilyId2 && newFamilyId2 !== oldFamilyId2) {
            promises.push(notifyFamilyMember(newFamilyId2, newUser, context));
        }

        if (newFamilyId3 && newFamilyId3 !== oldFamilyId3) {
            promises.push(notifyFamilyMember(newFamilyId3, newUser, context));
        }

        return Promise.all(promises);
    });

    async function notifyFamilyMember(familyId, newUser, context) {
    const querySnapshot = await admin.firestore().collection('users').where(
        Filter.or(
            Filter.where('familyId', '==', familyId),
            Filter.where('familyId2', '==', familyId),
            Filter.where('familyId3', '==', familyId),
        )
    ).get();

    const promises = [];

    querySnapshot.forEach(doc => {
        const existingUser = doc.data();
        const token = existingUser.tokenId;

        const notificationPayload = {
            notification: {
                title: 'Новый член семьи',
                body: `${newUser.email} присоединился к вашей семье.`,
            },
        };

        promises.push(admin.messaging().sendToDevice(token, notificationPayload));
    });

    return Promise.all(promises);
    }


